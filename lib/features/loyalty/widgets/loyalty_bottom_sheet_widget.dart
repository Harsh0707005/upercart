import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/loyalty/controllers/loyalty_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';

class LoyaltyBottomSheetWidget extends StatefulWidget {
  final String amount;
  const LoyaltyBottomSheetWidget({super.key, required this.amount});

  @override
  State<LoyaltyBottomSheetWidget> createState() => _LoyaltyBottomSheetWidgetState();
}

class _LoyaltyBottomSheetWidgetState extends State<LoyaltyBottomSheetWidget> {
  final TextEditingController _amountController = TextEditingController();
  String? _errorText;

  int? exchangePointRate = Get.find<SplashController>().configModel!.loyaltyPointExchangeRate ?? 0;
  int? minimumExchangePoint = Get.find<SplashController>().configModel!.minimumPointToTransfer ?? 0;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.amount;
  }

  void _validateAndConvert() {
    if(_amountController.text.isEmpty) {
      setState(() {
        _errorText = 'input_field_is_empty'.tr;
      });
      return;
    }

    int amount = int.parse(_amountController.text.trim());
    int? point = Get.find<ProfileController>().userInfoModel!.loyaltyPoint;

    if(amount < minimumExchangePoint!) {
      setState(() {
        _errorText = 'Please exchange more than $minimumExchangePoint ${'points'.tr}';
      });
    } else if(point! < amount) {
      setState(() {
        _errorText = 'you_do_not_have_enough_point_to_exchange'.tr;
      });
    } else {
      setState(() {
        _errorText = null;
      });
      Get.find<LoyaltyController>().pointToWallet(amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: ResponsiveHelper.isDesktop(context) ? 400 : 550,
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusExtraLarge)),
          ),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Image.asset(ResponsiveHelper.isDesktop(context) ? Images.loyaltyConvertIcon : Images.creditIcon, height: 50, width: 50),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(
                  '$exchangePointRate ${'points'.tr}= ',
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                ),
                Text(
                  PriceConverter.convertPrice(1), textDirection: TextDirection.ltr,
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                ),
              ]),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              Text(
                '(${'from'.tr} ${widget.amount} ${'points'.tr})',
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              Text(
                'amount_can_be_convert_into_wallet_money'.tr,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeExtraLarge : Dimensions.paddingSizeLarge),

              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: ResponsiveHelper.isDesktop(context) ? 260 : null,
                    child: CustomTextField(
                      titleText: 'enter_amount'.tr,
                      controller: _amountController,
                      inputType: TextInputType.phone,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _errorText!,
                        style: robotoRegular.copyWith(
                          color: Colors.red,
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),

              SizedBox(height: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeExtraLarge : Dimensions.paddingSizeLarge),

              GetBuilder<LoyaltyController>(builder: (walletController) {
                return CustomButton(
                  width: ResponsiveHelper.isDesktop(context) ? 136 : context.width/3,
                  isBold: false,
                  buttonText: 'convert'.tr,
                  radius: ResponsiveHelper.isDesktop(context) ? Dimensions.radiusSmall : 50,
                  isLoading: walletController.isLoading,
                  onPressed: _validateAndConvert,
                );
              }),
            ]),
          ),
        ),
        Positioned(
          top: 10, right: 10,
          child: IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.clear, size: 18),
          ),
        ),
      ],
    );
  }
}