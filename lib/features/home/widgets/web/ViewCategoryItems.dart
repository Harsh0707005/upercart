import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/card_design/item_card.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';

import '../../../../helper/route_helper.dart';

class CategoryItemsView extends StatefulWidget {
  final String categoryId;
  final String title;
  final bool isFood;
  final bool isShop;

  const CategoryItemsView({
    Key? key,
    required this.categoryId,
    required this.title,
    required this.isFood,
    required this.isShop,
  }) : super(key: key);

  @override
  State<CategoryItemsView> createState() => _CategoryItemsViewState();
}

class _CategoryItemsViewState extends State<CategoryItemsView> with AutomaticKeepAliveClientMixin {
  final ScrollController scrollController = ScrollController();
  bool showBackButton = false;
  bool showForwardButton = false;
  bool isFirstTime = true;
  bool _isInit = false;
  late CategoryController categoryController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_checkScrollPosition);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      // Initialize controller only once
      final String tag = 'category_controller_${widget.categoryId}';
      if (!Get.isRegistered<CategoryController>(tag: tag)) {
        categoryController = Get.put(
          CategoryController(categoryServiceInterface: Get.find()),
          tag: tag,
          permanent: true,
        );
        _loadItems();
      } else {
        categoryController = Get.find<CategoryController>(tag: tag);
        if (categoryController.categoryItemList == null) {
          _loadItems();
        }
      }
      _isInit = true;
    }
  }

  void _loadItems() {
    categoryController.getCategoryItemList(
      widget.categoryId,
      1,
      categoryController.type,
      true,
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _checkScrollPosition() {
    if (!mounted) return;
    setState(() {
      showBackButton = scrollController.position.pixels > 0;
      showForwardButton = scrollController.position.pixels < scrollController.position.maxScrollExtent;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GetBuilder<CategoryController>(
      tag: 'category_controller_${widget.categoryId}',
      builder: (catController) {
        List<Item>? itemList = catController.categoryItemList;

        if(itemList != null && itemList.length > 5 && isFirstTime) {
          showForwardButton = true;
          isFirstTime = false;
        }

        if (catController.isLoading) {
          return SizedBox(
            height: 285,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
            ),
          );
        }

        if (itemList == null || itemList.isEmpty) {
          return const SizedBox();
        }

        return Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(top: Dimensions.paddingSizeLarge, bottom: Dimensions.paddingSizeLarge),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeExtraLarge,
                      vertical: Dimensions.paddingSizeExtremeLarge,
                    ),
                    child: TitleWidget(
                      title: widget.title,
                      onTap: () => Get.toNamed(RouteHelper.getCategoryItemRoute(int.parse(widget.categoryId), widget.title)),
                    ),
                  ),

                  SizedBox(
                    height: 400,
                    width: Get.width,
                    child: ListView.builder(
                      controller: scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(left: Dimensions.paddingSizeExtraLarge),
                      itemCount: itemList.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: Dimensions.paddingSizeExtraLarge,
                            right: Dimensions.paddingSizeDefault,
                            top: Dimensions.paddingSizeExtraSmall,
                          ),
                          child: ItemCard(
                            key: ValueKey('${widget.categoryId}_item_$index'),
                            item: itemList[index],
                            isFood: widget.isFood,
                            isShop: widget.isShop,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            if(showBackButton)
              Positioned(
                top: 200,
                left: 0,
                child: InkWell(
                  onTap: () => scrollController.animateTo(
                    scrollController.offset - Dimensions.webMaxWidth,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    height: 40,
                    width: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).cardColor,
                      boxShadow: [BoxShadow(
                        color: Colors.grey[200]!,
                        blurRadius: 5,
                        spreadRadius: 1,
                      )],
                    ),
                    child: const Icon(Icons.arrow_back),
                  ),
                ),
              ),

            if(showForwardButton)
              Positioned(
                top: 200,
                right: 0,
                child: InkWell(
                  onTap: () => scrollController.animateTo(
                    scrollController.offset + Dimensions.webMaxWidth,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    height: 40,
                    width: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).cardColor,
                      boxShadow: [BoxShadow(
                        color: Colors.grey[200]!,
                        blurRadius: 5,
                        spreadRadius: 1,
                      )],
                    ),
                    child: const Icon(Icons.arrow_forward),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}