import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/features/home/widgets/highlight_widget.dart';
import 'package:sixam_mart/features/home/widgets/views/category_view.dart';
import 'package:sixam_mart/features/home/widgets/views/top_offers_near_me.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/features/home/widgets/bad_weather_widget.dart';
import 'package:sixam_mart/features/home/widgets/views/best_reviewed_item_view.dart';
// import 'package:sixam_mart/features/home/widgets/views/best_store_nearby_view.dart';
import 'package:sixam_mart/features/home/widgets/views/item_that_you_love_view.dart';
import 'package:sixam_mart/features/home/widgets/views/just_for_you_view.dart';
import 'package:sixam_mart/features/home/widgets/views/most_popular_item_view.dart';
import 'package:sixam_mart/features/home/widgets/views/new_on_mart_view.dart';
import 'package:sixam_mart/features/home/widgets/views/special_offer_view.dart';
import 'package:sixam_mart/features/home/widgets/views/visit_again_view.dart';
import 'package:sixam_mart/features/home/widgets/banner_view.dart';

import '../../widgets/web/WebViewCategoryItems.dart';

class FoodHomeScreen extends StatelessWidget {
  const FoodHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = AuthHelper.isLoggedIn();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Container(
        width: MediaQuery.of(context).size.width,
        decoration: Get.find<ThemeController>().darkTheme ? null : const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Images.foodModuleBannerBg),
            fit: BoxFit.cover,
          ),
        ),
        child: const Column(
          children: [
            BadWeatherWidget(),

            BannerView(isFeatured: false),
            SizedBox(height: 12),
          ],
        ),
      ),

      const CategoryView(),
      isLoggedIn ? const VisitAgainView(fromFood: true) : const SizedBox(),
      const SpecialOfferView(isFood: true, isShop: false),
      const HighlightWidget(),
      // const TopOffersNearMe(),
      // const BestReviewItemView(),
      // const BestStoreNearbyView(),
      // const ItemThatYouLoveView(forShop: false),
      const MostPopularItemView(isFood: true, isShop: false),
      const WebViewCategoryItems(categoryID: "643", categoryName: "Poultry", isFood: false, isShop: false),
      const WebViewCategoryItems(categoryID: "647", categoryName: "Seafood & Fish", isFood: false, isShop: false),
      const WebViewCategoryItems(categoryID: "638", categoryName: "Meat", isFood: false, isShop: false),
      const WebViewCategoryItems(categoryID: "651", categoryName: "Beverages", isFood: false, isShop: false),
      const WebViewCategoryItems(categoryID: "698", categoryName: "Oils, Baking & Condiments", isFood: false, isShop: false),
      const WebViewCategoryItems(categoryID: "721", categoryName: "Snacks", isFood: false, isShop: false),
      const WebViewCategoryItems(categoryID: "670", categoryName: "Prepared Foods", isFood: false, isShop: false),
      const WebViewCategoryItems(categoryID: "624", categoryName: "Fresh Bakery", isFood: false, isShop: false),
      const WebViewCategoryItems(categoryID: "609", categoryName: "Cookies, Desserts, and Ice Cream", isFood: false, isShop: false),
      const WebViewCategoryItems(categoryID: "514", categoryName: "Small Appliances", isFood: false, isShop: false),
      // const JustForYouView(),
      // const NewOnMartView(isNewStore: true, isPharmacy: false, isShop: false),
    ]);
  }
}
