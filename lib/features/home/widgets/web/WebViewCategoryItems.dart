import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/common/widgets/card_design/item_card.dart';
import 'package:sixam_mart/features/home/widgets/web/widgets/arrow_icon_button.dart';

import '../../../../helper/route_helper.dart';

class WebViewCategoryItems extends StatefulWidget {
  final String categoryID;
  final String categoryName;
  final bool isFood;
  final bool isShop;

  const WebViewCategoryItems({
    Key? key,
    required this.categoryID,
    required this.categoryName,
    required this.isFood,
    required this.isShop,
  }) : super(key: key);

  @override
  State<WebViewCategoryItems> createState() => _WebViewCategoryItemsState();
}

class _WebViewCategoryItemsState extends State<WebViewCategoryItems> {
  final ScrollController scrollController = ScrollController();
  bool showBackButton = false;
  bool showForwardButton = false;
  bool isFirstTime = true;

  late final CategoryController categoryController;

  @override
  void initState() {
    super.initState();
    categoryController = Get.put(CategoryController(
      categoryServiceInterface: Get.find(),
    ), tag: widget.categoryID); // Create unique instance with tag
    categoryController.getCategoryItemList(widget.categoryID, 1, 'all', false);

    scrollController.addListener(_checkScrollPosition);
    scrollController.addListener(_loadMoreData);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _checkScrollPosition() {
    setState(() {
      showBackButton = scrollController.position.pixels > 0;
      showForwardButton = scrollController.position.pixels < scrollController.position.maxScrollExtent;
    });
  }

  void _loadMoreData() {
    if (scrollController.position.pixels == scrollController.position.maxScrollExtent &&
        categoryController.categoryItemList != null &&
        !categoryController.isLoading) {
      final int pageSize = (categoryController.pageSize! / 10).ceil();
      if (categoryController.offset < pageSize) {
        categoryController.showBottomLoader();
        categoryController.getCategoryItemList(widget.categoryID, categoryController.offset + 1, 'all', false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(
      tag: widget.categoryID, // Use unique tag
      builder: (catController) {
        final itemList = catController.categoryItemList ?? [];

        if (itemList.length > 5 && isFirstTime) {
          showForwardButton = true;
          isFirstTime = false;
        }

        return Column(children: [
          if (catController.subCategoryList != null) Container(
            height: 40,
            width: Dimensions.webMaxWidth,
            margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: catController.subCategoryList!.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () => catController.setSubCategoryIndex(index, widget.categoryID),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                    margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      color: index == catController.subCategoryIndex
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        catController.subCategoryList![index].name!,
                        style: index == catController.subCategoryIndex
                            ? TextStyle(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor)
                            : TextStyle(fontSize: Dimensions.fontSizeSmall),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (itemList.isNotEmpty)
            Stack(children: [
              Container(
                margin: const EdgeInsets.only(top: Dimensions.paddingSizeLarge, bottom: Dimensions.paddingSizeLarge),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                ),
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge, vertical: Dimensions.paddingSizeExtremeLarge),
                    child: TitleWidget(
                        title: widget.categoryName,
                        onTap: () => Get.toNamed(RouteHelper.getCategoryItemRoute(int.parse(widget.categoryID), widget.categoryName)),
                    ),
                  ),
                  SizedBox(
                    height: 285,
                    width: Get.width,
                    child: ListView.builder(
                      controller: scrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: Dimensions.paddingSizeExtraLarge),
                      itemCount: itemList.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraLarge, right: Dimensions.paddingSizeDefault, top: Dimensions.paddingSizeExtraSmall),
                          child: ItemCard(
                            item: itemList[index],
                            isFood: widget.isFood,
                            isShop: widget.isShop,
                          ),
                        );
                      },
                    ),
                  ),
                ]),
              ),
              if (showBackButton)
                Positioned(
                  top: 200,
                  left: 0,
                  child: ArrowIconButton(
                    isRight: false,
                    onTap: () => scrollController.animateTo(
                      scrollController.offset - Dimensions.webMaxWidth,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
              if (showForwardButton)
                Positioned(
                  top: 200,
                  right: 0,
                  child: ArrowIconButton(
                    onTap: () => scrollController.animateTo(
                      scrollController.offset + Dimensions.webMaxWidth,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
            ])
          else
            const Center(child: CircularProgressIndicator()),
          if (catController.isLoading)
            const Padding(
              padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: CircularProgressIndicator(),
            ),
        ]);
      },
    );
  }
}