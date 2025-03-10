import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/search/controllers/search_controller.dart' as search;
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/item_view.dart';
import 'package:sixam_mart/common/widgets/web_item_view.dart';

class ItemViewWidget extends StatefulWidget {
  final bool isItem;
  const ItemViewWidget({super.key, required this.isItem});

  @override
  _ItemViewWidgetState createState() => _ItemViewWidgetState();
}

class _ItemViewWidgetState extends State<ItemViewWidget> {
  double? jmdRate;

  @override
  void initState() {
    super.initState();
    fetchUsdToJmdRate();
  }

  Future<void> fetchUsdToJmdRate() async {
    String url = 'https://open.er-api.com/v6/latest/USD';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          jmdRate = data['rates']['JMD'];
        });
      } else {
        setState(() {
          jmdRate = 157;
        });
      }
    } catch (e) {
      setState(() {
        jmdRate = 157;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<search.SearchController>(builder: (searchController) {
        return SingleChildScrollView(
          child: FooterView(
            child: SizedBox(
              width: Dimensions.webMaxWidth,
              child: ResponsiveHelper.isDesktop(context)
                  ? WebItemsView(
                isStore: widget.isItem,
                items: searchController.searchItemList,
                stores: searchController.searchStoreList,
              )
                  : ItemsView(
                isStore: widget.isItem,
                items: searchController.searchItemList,
                stores: searchController.searchStoreList,
                jmdRate: jmdRate,
              ),
            ),
          ),
        );
      }),
    );
  }
}
