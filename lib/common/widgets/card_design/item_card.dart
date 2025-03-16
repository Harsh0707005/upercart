import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/hover/text_hover.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/add_favourite_view.dart';
import 'package:sixam_mart/common/widgets/cart_count_view.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/discount_tag.dart';
import 'package:sixam_mart/common/widgets/hover/on_hover.dart';
import 'package:sixam_mart/common/widgets/not_available_widget.dart';
import 'package:sixam_mart/common/widgets/organic_tag.dart';
import 'package:http/http.dart' as http;

class ItemCard extends StatefulWidget {
  final Item item;
  final bool isPopularItem;
  final bool isFood;
  final bool isShop;
  final bool isPopularItemCart;
  final int? index;

  const ItemCard({
    super.key,
    required this.item,
    this.isPopularItem = false,
    required this.isFood,
    required this.isShop,
    this.isPopularItemCart = false,
    this.index,
  });

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  double? jmdPrice;
  String? _result;

  @override
  void initState() {
    super.initState();

    double? discount = widget.item.storeDiscount == 0 ? widget.item.discount : widget.item.storeDiscount;
    String? discountType = widget.item.storeDiscount == 0 ? widget.item.discountType : 'percent';

    print(Get.find<ItemController>().getStartingPrice(widget.item));
    usdTojmd(PriceConverter.convertPrice(
      Get.find<ItemController>().getStartingPrice(widget.item), discount: discount,
      discountType: discountType,
    ).substring(2));
    // print(PriceConverter.convertPrice(
    //   Get.find<ItemController>().getStartingPrice(widget.item), discount: discount,
    //   discountType: discountType,
    // ).substring(2));
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

  @override
  Widget build(BuildContext context) {
    double? discount = widget.item.storeDiscount == 0 ? widget.item.discount : widget.item.storeDiscount;
    String? discountType = widget.item.storeDiscount == 0 ? widget.item.discountType : 'percent';

    return OnHover(
      isItem: true,
      child: Stack(children: [
        Container(
          width: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            color: Theme.of(context).cardColor,
          ),
          child: CustomInkWell(
            onTap: () => Get.find<ItemController>().navigateToItemPage(widget.item, context),
            radius: Dimensions.radiusLarge,
            child: TextHover(
                builder: (isHovered) {
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    Expanded(
                      flex: 5,
                      child: Stack(children: [
                        Padding(
                          padding: EdgeInsets.only(top: widget.isPopularItem ? Dimensions.paddingSizeExtraSmall : 0, left: widget.isPopularItem ? Dimensions.paddingSizeExtraSmall : 0, right: widget.isPopularItem ? Dimensions.paddingSizeExtraSmall : 0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(Dimensions.radiusLarge),
                              topRight: const Radius.circular(Dimensions.radiusLarge),
                              bottomLeft: Radius.circular(widget.isPopularItem ? Dimensions.radiusLarge : 0),
                              bottomRight: Radius.circular(widget.isPopularItem ? Dimensions.radiusLarge : 0),
                            ),
                            child: CustomImage(
                              isHovered: isHovered,
                              placeholder: Images.placeholder,
                              image: '${widget.item.imageFullUrl}',
                              fit: BoxFit.cover, width: double.infinity, height: double.infinity,
                            ),
                          ),
                        ),

                        // AddFavouriteView(
                        //   item: item,
                        // ),

                        widget.item.isStoreHalalActive! && widget.item.isHalalItem! ? const Positioned(
                          top: 40, right: 15,
                          child: CustomAssetImageWidget(
                            Images.halalTag,
                            height: 20, width: 20,
                          ),
                        ) : const SizedBox(),

                        DiscountTag(
                          discount: discount,
                          discountType: discountType,
                          freeDelivery: false,
                        ),

                        OrganicTag(item: widget.item, placeInImage: false),

                        (widget.item.stock != null && widget.item.stock! < 0) ? Positioned(
                          bottom: 10, left : 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.5),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(Dimensions.radiusLarge),
                                bottomRight: Radius.circular(Dimensions.radiusLarge),
                              ),
                            ),
                            child: Text('out_of_stock'.tr, style: robotoRegular.copyWith(color: Theme.of(context).cardColor, fontSize: Dimensions.fontSizeSmall)),
                          ),
                        ) : const SizedBox(),

                        widget.isShop ? const SizedBox() : Positioned(
                          bottom: 10, right: 20,
                          child: CartCountView(
                            item: widget.item,
                            index: widget.index,
                          ),
                        ),

                        Get.find<ItemController>().isAvailable(widget.item) ? const SizedBox() : NotAvailableWidget(radius: Dimensions.radiusLarge, isAllSideRound: widget.isPopularItem),

                      ]),
                    ),

                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: EdgeInsets.only(left: Dimensions.paddingSizeSmall, right: widget.isShop ? 0 : Dimensions.paddingSizeSmall, top: Dimensions.paddingSizeSmall, bottom: widget.isShop ? 0 : Dimensions.paddingSizeSmall),
                        child: Stack(clipBehavior: Clip.none, children: [

                          Align(
                            alignment: widget.isPopularItem ? Alignment.center : Alignment.centerLeft,
                            child: Column(
                                crossAxisAlignment: widget.isPopularItem ? CrossAxisAlignment.center : CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                              (widget.isFood || widget.isShop) ? Text(widget.item.storeName ?? '', style: robotoRegular.copyWith(color: Theme.of(context).disabledColor))
                                  : Text(widget.item.name ?? '', textAlign: TextAlign.center, style: robotoBold, maxLines: 3, overflow: TextOverflow.ellipsis),

                              (widget.isFood || widget.isShop) ? Flexible(
                                child: Text(
                                  widget.item.name ?? '',
                                  style: robotoBold, maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ) : widget.item.ratingCount! > 0 ? Row(mainAxisAlignment: widget.isPopularItem ? MainAxisAlignment.center : MainAxisAlignment.start, children: [
                                Icon(Icons.star, size: 14, color: Theme.of(context).primaryColor),
                                const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                Text(widget.item.avgRating!.toStringAsFixed(1), style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
                                const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                Text("(${widget.item.ratingCount})", style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                              ]) : const SizedBox(),

                              // showUnitOrRattings(context);
                              (widget.isFood || widget.isShop) ? widget.item.ratingCount! > 0 ? Row(mainAxisAlignment: widget.isPopularItem ? MainAxisAlignment.center : MainAxisAlignment.start, children: [
                                Icon(Icons.star, size: 14, color: Theme.of(context).primaryColor),
                                const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                Text(widget.item.avgRating!.toStringAsFixed(1), style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
                                const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                Text("(${widget.item.ratingCount})", style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),

                              ]) : const SizedBox() : (Get.find<SplashController>().configModel!.moduleConfig!.module!.unit! && widget.item.unitType != null) ? Text(
                                '(${ widget.item.unitType ?? ''})',
                                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor),
                              ) : const SizedBox(),

                              discount != null && discount > 0  ? Text(
                                PriceConverter.convertPrice(Get.find<ItemController>().getStartingPrice(widget.item)),
                                style: robotoMedium.copyWith(
                                  fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor,
                                  decoration: TextDecoration.lineThrough,
                                ), textDirection: TextDirection.ltr,
                              ) : const SizedBox(),
                              // SizedBox(height: item.discount != null && item.discount! > 0 ? Dimensions.paddingSizeExtraSmall : 0),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "USD ${PriceConverter.convertPrice(
                                        Get.find<ItemController>().getStartingPrice(widget.item),
                                        discount: discount,
                                        discountType: discountType,
                                      )}",
                                      textDirection: TextDirection.ltr,
                                      style: robotoMedium,
                                    ),

                                    // const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                                    Text(
                                      jmdPrice != null && jmdPrice! > 0
                                          ? "JMD \$ ${jmdPrice?.toStringAsFixed(2)}"
                                          : "",
                                    ),
                                  ],
                                ),
                              ),


                              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                            ]),
                          ),

                          widget.isShop ? Positioned(
                            bottom: 0, right: 0,
                            child: CartCountView(
                              item: widget.item,
                              index: widget.index,
                              child: Container(
                                height: 35, width: 38,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(Dimensions.radiusLarge),
                                    bottomRight: Radius.circular(Dimensions.radiusLarge),
                                  ),
                                ),
                                child: Icon(widget.isPopularItemCart ? Icons.add_shopping_cart : Icons.add, color: Theme.of(context).cardColor, size: 20),
                              ),
                            ),
                          ) : const SizedBox(),
                        ]),
                      ),
                    ),
                  ]);
                }
            ),
          ),
        ),
      ]),
    );
  }

  // Widget? showUnitOrRattings(BuildContext context) {
  //   if(isFood || isShop) {
  //     if(item.ratingCount! > 0) {
  //       return Row(mainAxisAlignment: isPopularItem ? MainAxisAlignment.center : MainAxisAlignment.start, children: [
  //         Icon(Icons.star, size: 14, color: Theme.of(context).primaryColor),
  //         const SizedBox(width: Dimensions.paddingSizeExtraSmall),
  //
  //         Text(item.avgRating!.toStringAsFixed(1), style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
  //         const SizedBox(width: Dimensions.paddingSizeExtraSmall),
  //
  //         Text("(${item.ratingCount})", style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
  //
  //       ]);
  //     }
  //   } else if(Get.find<SplashController>().configModel!.moduleConfig!.module!.unit! && item.unitType != null) {
  //     return Text(
  //       '(${ item.unitType ?? ''})',
  //       style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor),
  //     );
  //   }
  // }

}