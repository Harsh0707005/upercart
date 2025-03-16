import 'package:flutter/material.dart';
import 'package:sixam_mart/features/flash_sale/widgets/flash_sale_view_widget.dart';
import 'package:sixam_mart/features/home/widgets/bad_weather_widget.dart';
import 'package:sixam_mart/features/home/widgets/highlight_widget.dart';
import 'package:sixam_mart/features/home/widgets/views/banner_view.dart';
import 'package:sixam_mart/features/home/widgets/views/best_reviewed_item_view.dart';
// import 'package:sixam_mart/features/home/widgets/views/best_store_nearby_view.dart';
import 'package:sixam_mart/features/home/widgets/views/category_view.dart';
import 'package:sixam_mart/features/home/widgets/views/promo_code_banner_view.dart';
import 'package:sixam_mart/features/home/widgets/views/item_that_you_love_view.dart';
import 'package:sixam_mart/features/home/widgets/views/just_for_you_view.dart';
import 'package:sixam_mart/features/home/widgets/views/most_popular_item_view.dart';
import 'package:sixam_mart/features/home/widgets/views/new_on_mart_view.dart';
import 'package:sixam_mart/features/home/widgets/views/middle_section_banner_view.dart';
import 'package:sixam_mart/features/home/widgets/views/special_offer_view.dart';
import 'package:sixam_mart/features/home/widgets/views/promotional_banner_view.dart';
import 'package:sixam_mart/features/home/widgets/views/top_offers_near_me.dart';
import 'package:sixam_mart/features/home/widgets/views/visit_again_view.dart';
import 'package:sixam_mart/helper/auth_helper.dart';

import '../../widgets/web/ViewCategoryItems.dart';
import '../../widgets/web/WebViewCategoryItems.dart';


class GroceryHomeScreen extends StatelessWidget {
  const GroceryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = AuthHelper.isLoggedIn();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Container(
        width: MediaQuery.of(context).size.width,
        color: Theme.of(context).disabledColor.withOpacity(0.1),
        child:  const Column(
          children: [
            BadWeatherWidget(),

            BannerView(isFeatured: false),
            SizedBox(height: 12),
          ],
        ),
      ),

      const CategoryView(),
      // isLoggedIn ? const VisitAgainView() : const SizedBox(),
      // const SpecialOfferView(isFood: false, isShop: false),
      const HighlightWidget(),
      // const FlashSaleViewWidget(),
      // const BestStoreNearbyView(),
      // const MostPopularItemView(isFood: false, isShop: false),
      const CategoryItemsView(
        categoryId: "643",
        title: "Poultry",
        isFood: false,
        isShop: false,
      ),
      const CategoryItemsView(
        categoryId: "647",
        title: "Seafood & Fish",
        isFood: false,
        isShop: false,
      ),
      const CategoryItemsView(
        categoryId: "638",
        title: "Meat",
        isFood: false,
        isShop: false,
      ),
      const CategoryItemsView(
        categoryId: "651",
        title: "Beverages",
        isFood: false,
        isShop: false,
      ),
      const CategoryItemsView(
        categoryId: "698",
        title: "Oils, Baking & Condiments",
        isFood: false,
        isShop: false,
      ),
      const CategoryItemsView(
        categoryId: "721",
        title: "Snacks",
        isFood: false,
        isShop: false,
      ),
      const CategoryItemsView(
        categoryId: "670",
        title: "Prepared Foods",
        isFood: false,
        isShop: false,
      ),
      const CategoryItemsView(
        categoryId: "624",
        title: "Fresh Bakery",
        isFood: false,
        isShop: false,
      ),
      const CategoryItemsView(
        categoryId: "609",
        title: "Cookies, Desserts, and Ice Cream",
        isFood: false,
        isShop: false,
      ),
      const CategoryItemsView(
        categoryId: "514",
        title: "Small Appliances",
        isFood: false,
        isShop: false,
      ),
      // const WebViewCategoryItems(categoryID: "643", categoryName: "Poultry", isFood: false, isShop: false),
      // const WebViewCategoryItems(categoryID: "647", categoryName: "Seafood & Fish", isFood: false, isShop: false),
      // const WebViewCategoryItems(categoryID: "638", categoryName: "Meat", isFood: false, isShop: false),
      // const WebViewCategoryItems(categoryID: "651", categoryName: "Beverages", isFood: false, isShop: false),
      // const WebViewCategoryItems(categoryID: "698", categoryName: "Oils, Baking & Condiments", isFood: false, isShop: false),
      // const WebViewCategoryItems(categoryID: "721", categoryName: "Snacks", isFood: false, isShop: false),
      // const WebViewCategoryItems(categoryID: "670", categoryName: "Prepared Foods", isFood: false, isShop: false),
      // const WebViewCategoryItems(categoryID: "624", categoryName: "Fresh Bakery", isFood: false, isShop: false),
      // const WebViewCategoryItems(categoryID: "609", categoryName: "Cookies, Desserts, and Ice Cream", isFood: false, isShop: false),
      // const WebViewCategoryItems(categoryID: "514", categoryName: "Small Appliances", isFood: false, isShop: false),
      // const MiddleSectionBannerView(),
      // const BestReviewItemView(),
      // const JustForYouView(),
      // const TopOffersNearMe(),
      // const ItemThatYouLoveView(forShop: false),
      isLoggedIn ? const PromoCodeBannerView() : const SizedBox(),
      // const NewOnMartView(isPharmacy: false, isShop: false),
      // const PromotionalBannerView(),
    ]);
  }
}
