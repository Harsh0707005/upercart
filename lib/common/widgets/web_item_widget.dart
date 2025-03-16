import 'dart:convert';

import 'package:sixam_mart/common/widgets/cart_count_view.dart';
import 'package:sixam_mart/common/widgets/custom_favourite_widget.dart';
import 'package:sixam_mart/common/widgets/hover/on_hover.dart';
import 'package:sixam_mart/common/widgets/hover/text_hover.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/discount_tag.dart';
import 'package:sixam_mart/common/widgets/not_available_widget.dart';
import 'package:sixam_mart/common/widgets/organic_tag.dart';
import 'package:sixam_mart/common/widgets/rating_bar.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class WebItemWidget extends StatefulWidget {
  final Item? item;
  final Store? store;
  final bool isStore;
  final int index;
  final int? length;
  final bool inStore;
  final bool isCampaign;
  final bool isFeatured;
  final bool fromCartSuggestion;

  const WebItemWidget({
    super.key,
    required this.item,
    required this.isStore,
    required this.store,
    required this.index,
    required this.length,
    this.inStore = false,
    this.isCampaign = false,
    this.isFeatured = false,
    this.fromCartSuggestion = false,
  });

  @override
  _WebItemWidgetState createState() => _WebItemWidgetState();
}

class _WebItemWidgetState extends State<WebItemWidget> {
  double? jmdPrice;
  String? _result;
  late bool isAvailable;
  late double? discount;
  late String? discountType;
  String genericName = '';

  @override
  void initState() {
    super.initState();
    _initializeData();

    usdTojmd(PriceConverter.convertPrice(widget.item!.price, discount: discount, discountType: discountType).substring(2));
  }

  Future<void> usdTojmd(amount) async {
    String url =
        'https://open.er-api.com/v6/latest/USD';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          jmdPrice = data['rates']['JMD']*double.parse(amount);
        });
      } else {
        setState(() {
          jmdPrice = 157*double.parse(amount);
          _result = 'Failed to fetch conversion rate!';
        });
      }
    } catch (e) {
      setState(() {
        jmdPrice = 157*double.parse(amount);
        _result = 'Error: $e';
      });
    }
  }

  void _initializeData() {
    if (!widget.isStore && widget.item!.genericName != null && widget.item!.genericName!.isNotEmpty) {
      for (String name in widget.item!.genericName!) {
        genericName += name;
      }
    }
    if (widget.isStore) {
      discount = widget.store!.discount != null ? widget.store!.discount!.discount : 0;
      discountType = widget.store!.discount != null ? widget.store!.discount!.discountType : 'percent';
      isAvailable = widget.store!.open == 1 && widget.store!.active!;
    } else {
      discount = (widget.item!.storeDiscount == 0 || widget.isCampaign) ? widget.item!.discount : widget.item!.storeDiscount;
      discountType = (widget.item!.storeDiscount == 0 || widget.isCampaign) ? widget.item!.discountType : 'percent';
      isAvailable = DateConverter.isAvailable(widget.item!.availableTimeStarts, widget.item!.availableTimeEnds);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool desktop = ResponsiveHelper.isDesktop(context);
    double? discount;
    String? discountType;
    bool isAvailable;
    String genericName = '';

    if (!widget.isStore &&
        widget.item!.genericName != null &&
        widget.item!.genericName!.isNotEmpty) {
      for (String name in widget.item!.genericName!) {
        genericName += name;
      }
    }
    if (widget.isStore) {
      discount = widget.store!.discount != null ? widget.store!.discount!.discount : 0;
      discountType =
      widget.store!.discount != null ? widget.store!.discount!.discountType : 'percent';
      isAvailable = widget.store!.open == 1 && widget.store!.active!;
    } else {
      discount = (widget.item!.storeDiscount == 0 || widget.isCampaign)
          ? widget.item!.discount
          : widget.item!.storeDiscount;
      discountType = (widget.item!.storeDiscount == 0 || widget.isCampaign)
          ? widget.item!.discountType
          : 'percent';
      isAvailable = DateConverter.isAvailable(
          widget.item!.availableTimeStarts, widget.item!.availableTimeEnds);
    }

    return TextHover(builder: (hovered) {
      return InkWell(
        onTap: () {
          if (widget.isStore) {
            if (widget.store != null) {
              if (widget.isFeatured &&
                  Get.find<SplashController>().moduleList != null) {
                for (ModuleModel module
                    in Get.find<SplashController>().moduleList!) {
                  if (module.id == widget.store!.moduleId) {
                    Get.find<SplashController>().setModule(module);
                    break;
                  }
                }
              }
              Get.toNamed(
                RouteHelper.getStoreRoute(
                    id: widget.store!.id, page: widget.isFeatured ? 'module' : 'item'),
                arguments: StoreScreen(store: widget.store, fromModule: widget.isFeatured),
              );
            }
          } else {
            if (widget.isFeatured && Get.find<SplashController>().moduleList != null) {
              for (ModuleModel module
                  in Get.find<SplashController>().moduleList!) {
                if (module.id == widget.item!.moduleId) {
                  Get.find<SplashController>().setModule(module);
                  break;
                }
              }
            }
            Get.find<ItemController>().navigateToItemPage(widget.item, context,
                inStore: widget.inStore, isCampaign: widget.isCampaign);
          }
        },
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        child: OnHover(
          isItem: true,
          child: Stack(
            children: [
              Container(
                margin: ResponsiveHelper.isDesktop(context)
                    ? null
                    : const EdgeInsets.only(
                        bottom: Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  color: Theme.of(context).cardColor,
                  border: Border.all(
                      color: Theme.of(context).disabledColor.withOpacity(0.1)),
                ),
                padding: const EdgeInsets.all(1),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: Column(children: [
                        Stack(children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                                topLeft:
                                    Radius.circular(Dimensions.radiusSmall),
                                topRight:
                                    Radius.circular(Dimensions.radiusSmall)),
                            child: CustomImage(
                              isHovered: hovered,
                              image:
                                  '${widget.isStore ? widget.store != null ? widget.store!.logoFullUrl : '' : widget.item!.imageFullUrl}',
                              height: desktop
                                  ? 140
                                  : widget.length == null
                                      ? 100
                                      : 65,
                              width: desktop
                                  ? widget.isStore
                                      ? 275
                                      : 300
                                  : 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          DiscountTag(
                            discount: discount,
                            discountType: discountType,
                            freeDelivery: widget.isStore ? widget.store!.freeDelivery : false,
                          ),
                          !widget.isStore
                              ? OrganicTag(
                                  item: widget.item!,
                                  placeInImage: false,
                                  placeTop: false)
                              : const SizedBox(),
                          widget.isStore
                              ? const SizedBox()
                              : Positioned(
                                  bottom: 10,
                                  right: 10,
                                  child: CartCountView(
                                    item: widget.item!,
                                    index: widget.index,
                                  ),
                                ),
                          isAvailable
                              ? const SizedBox()
                              : NotAvailableWidget(isStore: widget.isStore),
                        ]),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(
                                Dimensions.paddingSizeExtraSmall),
                            child: SizedBox(
                              width: desktop
                                  ? widget.isStore
                                      ? 275
                                      : 219
                                  : 80,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Wrap(
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            widget.isStore
                                                ? widget.store!.name!
                                                : widget.item!.name!,
                                            textAlign: TextAlign.center,
                                            style: robotoMedium.copyWith(
                                                fontSize: Dimensions
                                                    .fontSizeExtraSmall),
                                            maxLines: desktop ? 2 : 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(
                                              width: Dimensions
                                                  .paddingSizeExtraSmall),
                                          (Get.find<SplashController>()
                                                      .configModel!
                                                      .moduleConfig!
                                                      .module!
                                                      .vegNonVeg! &&
                                                  Get.find<SplashController>()
                                                      .configModel!
                                                      .toggleVegNonVeg!)
                                              ? Image.asset(
                                              widget.item != null && widget.item!.veg == 0
                                                      ? Images.nonVegImage
                                                      : Images.vegImage,
                                                  height: 10,
                                                  width: 10,
                                                  fit: BoxFit.contain)
                                              : const SizedBox(),
                                        ]),
                                    SizedBox(
                                        height: widget.isStore
                                            ? Dimensions.paddingSizeExtraSmall
                                            : 0),
                                    (genericName.isNotEmpty)
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 5.0),
                                            child: Text(
                                              genericName,
                                              style: robotoRegular.copyWith(
                                                fontSize: Dimensions
                                                    .fontSizeOverSmall,
                                                color: Theme.of(context)
                                                    .disabledColor,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          )
                                        : const SizedBox(),
                                    // (widget.isStore
                                    //         ? widget.store!.address != null
                                    //         : widget.item!.storeName != null)
                                    //     ? Text(
                                    //   widget.isStore
                                    //             ? widget.store!.address ?? ''
                                    //             : widget.item!.storeName ?? '',
                                    //         style: robotoRegular.copyWith(
                                    //           fontWeight: FontWeight.w300,
                                    //           fontSize:
                                    //               Dimensions.fontSizeOverSmall,
                                    //           color: widget.isStore
                                    //               ? Theme.of(context)
                                    //                   .disabledColor
                                    //               : Theme.of(context)
                                    //                   .primaryColor,
                                    //         ),
                                    //         maxLines: 1,
                                    //         overflow: TextOverflow.ellipsis,
                                    //       )
                                    //     : const SizedBox(),
                                    SizedBox(
                                        height: ((desktop || widget.isStore) &&
                                                (widget.isStore
                                                    ? widget.store!.address != null
                                                    : widget.item!.storeName != null))
                                            ? 5
                                            : 0),
                                    widget.isStore
                                        ? RatingBar(
                                            rating: widget.isStore
                                                ? widget.store!.avgRating
                                                : widget.item!.avgRating,
                                            size: desktop ? 15 : 12,
                                            ratingCount: widget.isStore
                                                ? widget.store!.ratingCount
                                                : widget.item!.ratingCount,
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Column(crossAxisAlignment: CrossAxisAlignment.start,
                                                        mainAxisSize: MainAxisSize.max,
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [

                                                    Text(
                                                      "USD ${PriceConverter.convertPrice(widget.item!.price, discount: discount, discountType: discountType)}",
                                                      style: robotoMedium.copyWith(
                                                          fontSize: Dimensions
                                                              .fontSizeExtraSmall),
                                                      textDirection:
                                                          TextDirection.ltr,
                                                    ),const SizedBox(width: 4),
                                                    jmdPrice!=null?
                                                    Text(
                                                      jmdPrice != null && jmdPrice! > 0
                                                          ? "(JMD \$ ${jmdPrice?.toStringAsFixed(2)})"
                                                          : "",
                                                      style: robotoMedium.copyWith(
                                                          color: Theme.of(context)
                                                              .primaryColor,
                                                          fontSize: Dimensions
                                                              .fontSizeExtraSmall),
                                                      textDirection:
                                                      TextDirection.ltr,
                                                    ):const SizedBox(width: 0),
                                                    ]),
                                                    SizedBox(
                                                        width: discount! > 0
                                                            ? Dimensions
                                                                .paddingSizeExtraSmall
                                                            : 0),
                                                    discount > 0
                                                        ? Text(
                                                            PriceConverter
                                                                .convertPrice(
                                                                widget.item!
                                                                        .price),
                                                            style: robotoMedium
                                                                .copyWith(
                                                              fontSize: Dimensions
                                                                  .fontSizeOverSmall,
                                                              color: Theme.of(
                                                                      context)
                                                                  .disabledColor,
                                                              decoration:
                                                                  TextDecoration
                                                                      .lineThrough,
                                                            ),
                                                            textDirection:
                                                                TextDirection
                                                                    .ltr,
                                                          )
                                                        : const SizedBox(),
                                                  ],
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 3,
                                                      horizontal: Dimensions
                                                          .paddingSizeSmall),
                                                  decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .primaryColor
                                                          .withOpacity(0.10),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              50)),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(Icons.star,
                                                          color:
                                                              Theme.of(context)
                                                                  .primaryColor,
                                                          size: 12),
                                                      const SizedBox(
                                                          width: Dimensions
                                                              .paddingSizeExtraSmall),
                                                      Text(
                                                        widget.item!.ratingCount
                                                            .toString(),
                                                        style: robotoRegular.copyWith(
                                                            fontSize: Dimensions
                                                                .fontSizeOverSmall,
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              ]),
                                  ]),
                            ),
                          ),
                        ),
                      ])),
                    ]),
              ),

              // Positioned(
              //   top: 10, right: 10,
              //   child: GetBuilder<FavouriteController>(builder: (favouriteController) {
              //     bool isWished = isStore ? favouriteController.wishStoreIdList.contains(store!.id) : favouriteController.wishItemIdList.contains(item!.id);
              //     return CustomFavouriteWidget(
              //       isWished: isWished,
              //       isStore: isStore,
              //       store: store,
              //       item: item,
              //     );
              //   }),
              // ),
            ],
          ),
        ),
      );
    });
  }
}
