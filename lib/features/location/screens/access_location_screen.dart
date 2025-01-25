import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/common/widgets/address_widget.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_loader.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/location/screens/pick_map_screen.dart';
import 'package:sixam_mart/features/location/screens/web_landing_page.dart';

import '../../../api/api_client.dart';
import '../../../util/app_constants.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/domain/reposotories/deliveryman_registration_repository.dart';
import '../../profile/controllers/profile_controller.dart';
import '../domain/models/zone_data_model.dart';

class AccessLocationScreen extends StatefulWidget {
  final bool fromSignUp;
  final bool fromHome;
  final String? route;
  const AccessLocationScreen({super.key, required this.fromSignUp, required this.fromHome, required this.route});

  @override
  State<AccessLocationScreen> createState() => _AccessLocationScreenState();
}

class _AccessLocationScreenState extends State<AccessLocationScreen> {
  bool _canExit = GetPlatform.isWeb ? true : false;

  @override
  void initState() {
    super.initState();
    if(AuthHelper.isLoggedIn()) {
      Get.find<AddressController>().getAddressList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (_canExit) {
          if (GetPlatform.isAndroid) {
            SystemNavigator.pop();
          } else if (GetPlatform.isIOS) {
            exit(0);
          } else {
            Navigator.pushNamed(context, RouteHelper.getInitialRoute());
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('back_press_again_to_exit'.tr, style: const TextStyle(color: Colors.white)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          ));
          _canExit = true;
          Timer(const Duration(seconds: 2), () {
            _canExit = false;
          });
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(title: 'set_location'.tr, backButton: widget.fromHome),
        endDrawer: const MenuDrawer(),endDrawerEnableOpenDragGesture: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(child: Padding(
          padding: ResponsiveHelper.isDesktop(context) ? EdgeInsets.zero : const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: GetBuilder<AddressController>(builder: (locationController) {
            bool isLoggedIn = AuthHelper.isLoggedIn();
            return (ResponsiveHelper.isDesktop(context) && AddressHelper.getUserAddressFromSharedPref() == null) ? WebLandingPage(
              fromSignUp: widget.fromSignUp, fromHome: widget.fromHome, route: widget.route,
            ) : isLoggedIn ? Column(children: [
              Expanded(child: SingleChildScrollView(
                child: FooterView(child: Column(mainAxisAlignment: (locationController.addressList != null && locationController.addressList!.isNotEmpty) ? MainAxisAlignment.start : MainAxisAlignment.center, children: [

                  locationController.addressList != null ? locationController.addressList!.isNotEmpty ? ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: locationController.addressList!.length,
                    itemBuilder: (context, index) {
                      return Center(child: SizedBox(width: 700, child: AddressWidget(
                        address: locationController.addressList![index],
                        fromAddress: false,
                        onTap: () {
                          Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
                          AddressModel address = locationController.addressList![index];
                          Get.find<LocationController>().saveAddressAndNavigate(
                            address, widget.fromSignUp, widget.route, widget.route != null, ResponsiveHelper.isDesktop(context),
                          );
                        },
                      )));
                    },
                  ) : NoDataScreen(text: 'no_saved_address_found'.tr) : const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  ResponsiveHelper.isDesktop(context) ? BottomButton(fromSignUp: widget.fromSignUp, route: widget.route) : const SizedBox(),

                ])),
              )),
              ResponsiveHelper.isDesktop(context) ? const SizedBox() : BottomButton(fromSignUp: widget.fromSignUp, route: widget.route),
            ]) : Center(child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: FooterView(child: SizedBox( width: 700,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center,children: [
                    Image.asset(Images.deliveryLocation, height: 220),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    Text('find_stores_and_items'.tr.toUpperCase(), textAlign: TextAlign.center, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
                    Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                      child: Text('by_allowing_location_access'.tr, textAlign: TextAlign.center,
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    Padding(
                      padding: ResponsiveHelper.isWeb() ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                      child: BottomButton(fromSignUp: widget.fromSignUp, route: widget.route),
                    ),
              ]))),
            ));
          }),
        )),
      ),
    );
  }
}

class BottomButton extends StatefulWidget {
  final bool fromSignUp;
  final String? route;

  const BottomButton({super.key, required this.fromSignUp, required this.route});

  @override
  _BottomButtonState createState() => _BottomButtonState();
}

class _BottomButtonState extends State<BottomButton> {
  bool _zoneLoaded = false;
  ZoneDataModel? _selectedZone;
  List<ZoneDataModel> _zoneList = [];
  AddressModel? _address;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchZoneList(); // Call fetchZoneList here so it's executed only once
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
    return Center(child: SizedBox(width: 700, child: Column(children: [

      // CustomButton(
      //   buttonText: 'user_current_location'.tr,
      //   onPressed: () async {
      //     Get.find<LocationController>().checkPermission(() async {
      //       Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
      //       AddressModel address = await Get.find<LocationController>().getCurrentLocation(true);
      //       ZoneResponseModel response = await Get.find<LocationController>().getZone(address.latitude, address.longitude, false);
      //       if(response.isSuccess) {
      //         Get.find<LocationController>().saveAddressAndNavigate(
      //           address, widget.fromSignUp, widget.route, widget.route != null, ResponsiveHelper.isDesktop(Get.context),
      //         );
      //       }else {
      //         Get.back();
      //         if(ResponsiveHelper.isDesktop(Get.context)) {
      //           showGeneralDialog(context: Get.context!, pageBuilder: (_,__,___) {
      //             return SizedBox(
      //                 height: 300, width: 300,
      //                 child: PickMapScreen(fromSignUp: widget.fromSignUp, canRoute: widget.route != null, fromAddAddress: false, route: widget.route ?? RouteHelper.accessLocation)
      //             );
      //           });
      //         }else {
      //           Get.toNamed(RouteHelper.getPickMapRoute(widget.route ?? RouteHelper.accessLocation, widget.route != null));
      //           showCustomSnackBar('service_not_available_in_current_location'.tr);
      //         }
      //       }
      //     });
      //   },
      //   icon: Icons.my_location,
      // ),

      // Expanded(
      //   flex: 3,
      //   child: _zoneLoaded
      //       ? Container(
      //     decoration: BoxDecoration(
      //       color: Colors.white,
      //       borderRadius: BorderRadius.circular(10),
      //       border: Border.all(
      //         color: Theme.of(context).primaryColor.withOpacity(0.3),
      //         width: 1,
      //       ),
      //     ),
      //     child: Padding(
      //       padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge), // Adjust padding as needed
      //       child: DropdownButton<ZoneDataModel>(
      //         iconSize: 0,
      //         underline: Container(),
      //         value: _selectedZone,
      //         dropdownColor: Colors.white, // Sets dropdown menu background to white
      //         style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold), // Optional: sets text color
      //         items: [
      //           DropdownMenuItem<ZoneDataModel>(
      //             value: null,
      //             enabled: false,
      //             child: Text(
      //               'Choose a delivery zone',
      //               style: TextStyle(color: Theme.of(context).disabledColor),
      //             ), // Makes this item unselectable
      //           ),
      //           ..._zoneList.map((zone) {
      //             return DropdownMenuItem<ZoneDataModel>(
      //               value: zone,
      //               child: Text(zone.name ?? ''),
      //             );
      //           }).toList(),
      //         ],
      //         onChanged: (ZoneDataModel? newZone) {
      //           setState(() {
      //             _selectedZone = newZone;
      //           });
      //         },
      //         hint: Text(
      //           _zoneList.isEmpty ? 'No zones available' : 'Select Zone',
      //           style: TextStyle(color: Theme.of(context).disabledColor),
      //         ),
      //       ),
      //     ),
      //
      //   )
      //       : const SizedBox(width: Dimensions.paddingSizeSmall),
      // ),

      Container(
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

      ),


      const SizedBox(height: Dimensions.paddingSizeSmall),

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
                zoneId: _selectedZone!.id,
                address: _selectedZone!.name.toString(),
                addressType: "others"
            );
            // print('ID: ${_address?.id}');
            // print('Address Type: ${_address?.addressType}');
            // print('Contact Person Number: ${_address?.contactPersonNumber}');
            // print('Address: ${_address?.address}');
            // print('Additional Address: ${_address?.additionalAddress}');
            // print('Latitude: ${_address?.latitude}');
            // print('Longitude: ${_address?.longitude}');
            // print('Zone ID: ${_address?.zoneId}');
            // print('Zone IDs: ${_address?.zoneIds}');
            // print('Method: ${_address?.method}');
            // print('Contact Person Name: ${_address?.contactPersonName}');
            // print('Street Number: ${_address?.streetNumber}');
            // print('House: ${_address?.house}');
            // print('Floor: ${_address?.floor}');
            // print('Zone Data: ${_address?.zoneData}');
            // print('Area IDs: ${_address?.areaIds}');
            // print('Email: ${_address?.email}');
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

      // TextButton(
      //   style: TextButton.styleFrom(
      //     shape: RoundedRectangleBorder(
      //       side: BorderSide(width: 1, color: Theme.of(context).primaryColor),
      //       borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      //     ),
      //     minimumSize: const Size(Dimensions.webMaxWidth, 50),
      //     padding: EdgeInsets.zero,
      //   ),
      //   onPressed: () {
      //     if(ResponsiveHelper.isDesktop(Get.context)) {
      //       showGeneralDialog(context: Get.context!, pageBuilder: (_,__,___) {
      //         return SizedBox(
      //             height: 300, width: 300,
      //             child: PickMapScreen(fromSignUp: widget.fromSignUp, canRoute: widget.route != null, fromAddAddress: false, route: widget.route ?? RouteHelper.accessLocation)
      //         );
      //       });
      //     }else {
      //       Get.toNamed(RouteHelper.getPickMapRoute(
      //         widget.route ?? (widget.fromSignUp ? RouteHelper.signUp : RouteHelper.accessLocation), widget.route != null,
      //       ));
      //     }
      //   },
      //   child: Row( // The Row content remains unchanged.
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: [
      //       Icon(Icons.map, color: Theme.of(context).primaryColor),
      //       const SizedBox(width: Dimensions.paddingSizeSmall),
      //       Text('set_location_manually'.tr, style: robotoBold.copyWith(color: Theme.of(context).primaryColor)),
      //     ],
      //   ),
      // ),
    ])));
  }
}
