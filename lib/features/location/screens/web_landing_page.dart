import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/common/widgets/custom_tool_tip_widget.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/location/widgets/dynamic_text_color.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/location/domain/models/prediction_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/location/widgets/web_landing_page_shimmer_widget.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_loader.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/features/location/screens/pick_map_screen.dart';
import 'package:sixam_mart/features/location/widgets/landing_card_widget.dart';
import 'package:sixam_mart/features/location/widgets/registration_card_widget.dart';
// import 'package:universal_html/html.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:intl/intl.dart' as intl;

import '../../../api/api_client.dart';
import '../../auth/domain/reposotories/deliveryman_registration_repository.dart';
import '../domain/models/zone_data_model.dart';

LatLng generateRandomPointInPolygon(List<LatLng> polygonCoordinates) {
  if (polygonCoordinates.isEmpty) {
    throw ArgumentError('Polygon coordinates list cannot be empty');
  }

  // First, find the bounding box of the polygon
  double minLat = polygonCoordinates[0].latitude;
  double maxLat = polygonCoordinates[0].latitude;
  double minLng = polygonCoordinates[0].longitude;
  double maxLng = polygonCoordinates[0].longitude;

  for (var point in polygonCoordinates) {
    minLat = min(minLat, point.latitude);
    maxLat = max(maxLat, point.latitude);
    minLng = min(minLng, point.longitude);
    maxLng = max(maxLng, point.longitude);
  }

  // Create a random number generator
  final random = Random();

  // Maximum attempts to find a point (to prevent infinite loops)
  const maxAttempts = 1000;
  var attempts = 0;

  while (attempts < maxAttempts) {
    // Generate a random point within the bounding box
    double lat = minLat + random.nextDouble() * (maxLat - minLat);
    double lng = minLng + random.nextDouble() * (maxLng - minLng);

    LatLng point = LatLng(lat, lng);

    // Check if the point is inside the polygon
    if (isPointInPolygon(point, polygonCoordinates)) {
      return point;
    }
    attempts++;
  }

  // If we couldn't find a point after max attempts, return the center of the polygon
  return LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2
  );
}

/// Checks if a point lies inside a polygon using the ray casting algorithm
bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
  if (polygon.length < 3) return false;  // A polygon must have at least 3 points

  bool inside = false;
  int j = polygon.length - 1;

  for (int i = 0; i < polygon.length; i++) {
    double xi = polygon[i].longitude;
    double yi = polygon[i].latitude;
    double xj = polygon[j].longitude;
    double yj = polygon[j].latitude;

    // Handle possible division by zero or infinity
    if (xi == xj) continue;

    bool intersect = ((yi > point.latitude) != (yj > point.latitude)) &&
        (point.longitude < (xj - xi) * (point.latitude - yi) / (yj - yi) + xi);

    if (intersect) inside = !inside;
    j = i;
  }

  return inside;
}

class WebLandingPage extends StatefulWidget {
  final bool fromSignUp;
  final bool fromHome;
  final String? route;
  const WebLandingPage({super.key, required this.fromSignUp, required this.fromHome, required this.route});

  @override
  State<WebLandingPage> createState() => _WebLandingPageState();
}

class _WebLandingPageState extends State<WebLandingPage> {
  final TextEditingController _controller = TextEditingController();
  final PageController _pageController = PageController();
  AddressModel? _address;
  Timer? _timer;
  bool? _isRtl;
  bool _zoneLoaded = false;
  ZoneDataModel? _selectedZone;
  List<ZoneDataModel> _zoneList = [];

  @override
  void initState() {
    super.initState();

    if(Get.find<SplashController>().moduleList == null) {
      if (kDebugMode) {
        print('-------call from web landing page------------');
      }
      Get.find<SplashController>().getModules(headers: {'Content-Type': 'application/json; charset=UTF-8', AppConstants.localizationKey: Get.find<LocalizationController>().locale.languageCode});
    }
    fetchZoneList();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchZoneList() async {
    // Initialize dependencies
    final sharedPreferences = await SharedPreferences.getInstance();
    final apiClient = ApiClient(appBaseUrl: AppConstants.baseUrl, sharedPreferences: Get.find()); // Make sure it's correctly implemented

    // Create an instance of the repository
    final repository = DeliverymanRegistrationRepository(
      sharedPreferences: sharedPreferences,
      apiClient: apiClient,
    );

    // Fetch zone list
    try {
      final zoneList = await repository.getList(isZone: true) as List<ZoneDataModel>?;
      if (zoneList != null) {
        zoneList.forEach((zone) {
          print('Zone ID: ${zone.id}, Zone Name: ${zone.name}, Zone coordinates: ${zone.coordinates?.coordinates?.map((latLng) => '(${latLng.latitude}, ${latLng.longitude})').join(", ")}');
        });
        _zoneList = zoneList;
      } else {
        print('Zone list is empty.');
      }
      setState(() {
        _zoneLoaded = true;
      });
    } catch (e) {
      print('Error fetching zone list: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    _isRtl = intl.Bidi.isRtlLanguage(Get.locale!.languageCode);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: FooterView(child: SizedBox(width: Dimensions.webMaxWidth, child: GetBuilder<SplashController>(
        builder: (splashController) {
          return splashController.landingModel == null ? const WebLandingPageShimmerWidget() : Column(children: [

            const SizedBox(height: Dimensions.paddingSizeLarge),

            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                color: Theme.of(context).primaryColor.withOpacity(0.05),
              ),
              child: Row(children: [
                const SizedBox(width: 40),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [

                  Text(splashController.landingModel?.fixedHeaderTitle ?? '', style: robotoBold.copyWith(fontSize: 35)),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  Text(
                    splashController.landingModel?.fixedHeaderSubTitle ?? '',
                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor),
                  ),
                ])),
                Expanded(child: ClipPath(clipper: CustomPath(isRtl: _isRtl), child: ClipRRect(
                  borderRadius: BorderRadius.horizontal(
                    right: _isRtl! ? const Radius.circular(0) : const Radius.circular(Dimensions.radiusDefault),
                    left: _isRtl! ? const Radius.circular(Dimensions.radiusDefault) : const Radius.circular(0),
                  ),
                  child: CustomImage(
                    image: '${splashController.landingModel != null ? splashController.landingModel!.fixedHeaderImageFullUrl : ''}',
                    height: 270, fit: BoxFit.cover,
                  ),
                ))),
              ]),
            ),
            const SizedBox(height: 20),

            Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                child: Opacity(opacity: 0.05, child: Image.asset(Images.landingBg, height: 130, width: context.width, fit: BoxFit.fill)),
              ),
              Container(
                height: 130,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  color: Theme.of(context).primaryColor.withOpacity(0.05),
                ),
                child: Row(children: [
                  Expanded(flex: 3, child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: Column(children: [
                      Image.asset(Images.landingChooseLocation, height: 70, width: 70),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                        child: Text(
                          splashController.landingModel?.fixedLocationTitle ?? '', textAlign: TextAlign.center,
                          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                        ),
                      ),
                    ]),
                  )),
                  Expanded(flex: 7, child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                    child: Row(children: [
                      // Expanded(child: TypeAheadField(
                      //   textFieldConfiguration: TextFieldConfiguration(
                      //     controller: _controller,
                      //     textInputAction: TextInputAction.search,
                      //     textCapitalization: TextCapitalization.words,
                      //     keyboardType: TextInputType.streetAddress,
                      //     decoration: InputDecoration(
                      //       hintText: 'search_location'.tr,
                      //       border: OutlineInputBorder(
                      //         borderRadius: BorderRadius.circular(10),
                      //         borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3), width: 1),
                      //       ),
                      //       enabledBorder: OutlineInputBorder(
                      //         borderRadius: BorderRadius.circular(10),
                      //         borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3), width: 1),
                      //       ),
                      //       hintStyle: Theme.of(context).textTheme.displayMedium!.copyWith(
                      //         fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).disabledColor,
                      //       ),
                      //       filled: true, fillColor: Theme.of(context).cardColor,
                      //       suffixIcon: IconButton(
                      //         onPressed: () async {
                      //           Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
                      //           _address = await Get.find<LocationController>().getCurrentLocation(true);
                      //           _controller.text = _address!.address ?? '';
                      //           Get.back();
                      //         },
                      //         icon: Icon(Icons.my_location, color: Theme.of(context).primaryColor),
                      //       ),
                      //     ),
                      //     style: Theme.of(context).textTheme.displayMedium!.copyWith(
                      //       color: Theme.of(context).textTheme.bodyLarge!.color, fontSize: Dimensions.fontSizeLarge,
                      //     ),
                      //   ),
                      //   suggestionsCallback: (pattern) async {
                      //     return await Get.find<LocationController>().searchLocation(context, pattern);
                      //   },
                      //   itemBuilder: (context, PredictionModel suggestion) {
                      //     return Padding(
                      //       padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      //       child: Row(children: [
                      //         const Icon(Icons.location_on),
                      //         Expanded(child: Text(
                      //           suggestion.description ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                      //           style: Theme.of(context).textTheme.displayMedium!.copyWith(
                      //             color: Theme.of(context).textTheme.bodyLarge!.color, fontSize: Dimensions.fontSizeLarge,
                      //           ),
                      //         )),
                      //       ]),
                      //     );
                      //   },
                      //   onSuggestionSelected: (PredictionModel suggestion) async {
                      //     _controller.text = suggestion.description ?? '';
                      //     _address = await Get.find<LocationController>().setLocation(suggestion.placeId, suggestion.description, null);
                      //   },
                      // )),

                      _zoneLoaded ? () {
                        debugPrint('zone loaded: $_zoneLoaded');
                        debugPrint('zone list: $_zoneList');
                        return const SizedBox.shrink(); // Placeholder widget for prints
                      }():const SizedBox(width: Dimensions.paddingSizeSmall),

                      Expanded(
                        flex: 3,
                        child: _zoneLoaded
                            ? Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge), // Adjust padding as needed
                            child: DropdownButton<ZoneDataModel>(
                              iconSize: 0,
                              underline: Container(),
                              value: _selectedZone,
                              dropdownColor: Colors.white, // Sets dropdown menu background to white
                              style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold), // Optional: sets text color
                              items: [
                                DropdownMenuItem<ZoneDataModel>(
                                  value: null,
                                  enabled: false,
                                  child: Text(
                                    'Choose a delivery zone',
                                    style: TextStyle(color: Theme.of(context).disabledColor),
                                  ), // Makes this item unselectable
                                ),
                                ..._zoneList.map((zone) {
                                  return DropdownMenuItem<ZoneDataModel>(
                                    value: zone,
                                    child: Text(zone.name ?? ''),
                                  );
                                }).toList(),
                              ],
                              onChanged: (ZoneDataModel? newZone) {
                                setState(() {
                                  _selectedZone = newZone;
                                });
                              },
                              hint: Text(
                                _zoneList.isEmpty ? 'No zones available' : 'Select Zone',
                                style: TextStyle(color: Theme.of(context).disabledColor),
                              ),
                            ),
                          ),

                        )
                            : const SizedBox(width: Dimensions.paddingSizeSmall),
                      ),


                      const SizedBox(width: Dimensions.paddingSizeSmall),


                      CustomButton(
                        width: 150, height: 60, fontSize: Dimensions.fontSizeDefault,
                        buttonText: 'set_location'.tr,
                        onPressed: () async {

                          print('Zone ID: ${_selectedZone!.id}, Zone Name: ${_selectedZone!.name}, Zone coordinates: ${_selectedZone!.coordinates?.coordinates?.map((latLng) => '(${latLng.latitude}, ${latLng.longitude})').join(", ")}');

                          String latitude = _selectedZone!.coordinates!.coordinates![0].latitude.toString();
                          String longitude = _selectedZone!.coordinates!.coordinates![0].longitude.toString();
                          print(latitude+" " +longitude);
                          // try {
                          //   _address = AddressModel(
                          //       latitude: "18.0179",
                          //       longitude: "76.8099",
                          //       // zoneId: _selectedZone!.id
                          //       zoneId: 2,
                          //     address: _selectedZone!.name.toString()
                          //   );
                          //   _controller.text = _selectedZone!.name.toString();
                          //   print(_controller.text);
                          //
                          // }catch(e){
                          //   print(e);
                          // }

                          try {
                            // Generate random point inside the polygon
                            LatLng randomPoint = generateRandomPointInPolygon(
                                _selectedZone!.coordinates!.coordinates!
                            );

                            // Update address model
                            _address = AddressModel(
                                latitude: randomPoint.longitude.toString(),
                                longitude: randomPoint.latitude.toString(),
                                zoneId: 2,
                                address: _selectedZone!.name.toString()
                            );

                            _controller.text = _selectedZone!.name.toString();
                          } catch (e) {
                            print('Error generating random point: $e');
                          }

                          if(_address != null && _controller.text.trim().isNotEmpty) {

                            Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
                            // ZoneResponseModel response = await Get.find<LocationController>().getZone(
                            //   _address!.latitude, _address!.longitude, false,
                            // );
                            ZoneResponseModel response = await Get.find<LocationController>().getZone(
                              _address!.latitude, _address!.longitude, false,
                            );
                            // ZoneResponseModel response = await Get.find<LocationController>().getZone(
                            //   latitude, longitude, false,
                            // );
                            if(response.isSuccess) {
                              if(!AuthHelper.isGuestLoggedIn() && !AuthHelper.isLoggedIn()) {
                                Get.find<AuthController>().guestLogin().then((response) {
                                  if(response.isSuccess) {
                                    Get.find<ProfileController>().setForceFullyUserEmpty();
                                    Get.find<LocationController>().saveAddressAndNavigate(
                                      _address, widget.fromSignUp, widget.route, widget.route != null, ResponsiveHelper.isDesktop(Get.context),
                                    );
                                  }
                                });
                              } else {
                                Get.find<LocationController>().saveAddressAndNavigate(
                                  _address, widget.fromSignUp, widget.route, widget.route != null, ResponsiveHelper.isDesktop(Get.context),
                                );
                              }
                            }else {
                              Get.back();
                              showCustomSnackBar('service_not_available_in_current_location'.tr);
                            }
                          }else {
                            showCustomSnackBar('pick_an_address'.tr);
                          }
                        },
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),

                      // CustomButton(
                      //   width: 160, height: 60, fontSize: Dimensions.fontSizeDefault,
                      //   buttonText: 'pick_from_map'.tr,
                      //   onPressed: () {
                      //     if(ResponsiveHelper.isDesktop(Get.context)) {
                      //
                      //       showGeneralDialog(context: context, pageBuilder: (_,__,___) {
                      //         return SizedBox(
                      //           height: 300, width: 300,
                      //           child: PickMapScreen(
                      //             fromSignUp: widget.fromSignUp, canRoute: widget.route != null, fromAddAddress: false, route: widget.route
                      //               ?? (widget.fromSignUp ? RouteHelper.signUp : RouteHelper.accessLocation), fromLandingPage: true,
                      //           ),
                      //         );
                      //       });
                      //     }else {
                      //       Get.toNamed(RouteHelper.getPickMapRoute(
                      //         widget.route ?? (widget.fromSignUp ? RouteHelper.signUp : RouteHelper.accessLocation), widget.route != null,
                      //       ));
                      //     }
                      //   }
                      //   // onPressed: (){
                      //   //   Get.dialog(const PickMapScreen(fromSignUp: false, canRoute: false, fromAddAddress: false, route: null ));
                      //   // }
                      // ),
                    ]),
                  )),
                ]),
              ),
            ]),
            const SizedBox(height: 40),

          ]);
        }
      ))),
    );
  }
}

class CustomPath extends CustomClipper<Path> {
  final bool? isRtl;
  CustomPath({required this.isRtl});

  @override
  Path getClip(Size size) {
    final path = Path();
    if(isRtl!) {
      path..moveTo(0, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width*0.7, 0)
        ..lineTo(0, 0)
        ..close();
    }else {
      path..moveTo(0, size.height)
        ..lineTo(size.width*0.3, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, size.height)
        ..close();
    }
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}
