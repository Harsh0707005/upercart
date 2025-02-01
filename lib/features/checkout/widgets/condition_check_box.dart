import 'package:flutter/gestures.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CheckoutCondition extends StatefulWidget {
  final bool isParcel;
  final Function(bool) onCheckboxChanged;
  final bool isChecked;
  const CheckoutCondition({super.key, this.isParcel = false, required this.onCheckboxChanged, required this.isChecked});

  @override
  _CheckoutConditionState createState() => _CheckoutConditionState();
}

class _CheckoutConditionState extends State<CheckoutCondition> {
  // bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    bool activeRefund = Get.find<SplashController>().configModel!.refundPolicyStatus == 1;

    return Row(
      children: [
        // Checkbox to accept terms
        SizedBox(
          width: 24.0,
          height: 24.0,
          child: Checkbox(
            activeColor: Theme.of(context).primaryColor,
            value: widget.isChecked, // This will manage the checked state
            onChanged: (bool? newCheckedValue) {
              if (newCheckedValue != null) {
                widget.onCheckboxChanged(newCheckedValue);
              }
            },
          ),
        ),
        const SizedBox(width: 8.0), // Padding between checkbox and text

        // Terms & Conditions Text
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${'i_have_read_and_agreed_with'.tr} ',
                  style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyMedium!.color),
                ),
                TextSpan(
                  text: 'privacy_policy'.tr,
                  style: robotoMedium.copyWith(color: Theme.of(context).primaryColor),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => Get.toNamed(RouteHelper.getHtmlRoute('privacy-policy')),
                ),
                !widget.isParcel && activeRefund
                    ? TextSpan(
                  text: ', ',
                  style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyMedium!.color),
                )
                    : TextSpan(
                  text: ' ${'and'.tr} ',
                  style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyMedium!.color),
                ),
                TextSpan(
                  text: 'terms_conditions'.tr,
                  style: robotoMedium.copyWith(color: Theme.of(context).primaryColor),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => Get.toNamed(RouteHelper.getHtmlRoute('terms-and-condition')),
                ),
                !widget.isParcel && activeRefund
                    ? TextSpan(
                  text: ' ${'and'.tr} ',
                  style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyMedium!.color),
                )
                    : const TextSpan(),

                !widget.isParcel && activeRefund
                    ? TextSpan(
                  text: 'refund_policy'.tr,
                  style: robotoMedium.copyWith(color: Theme.of(context).primaryColor),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => Get.toNamed(RouteHelper.getHtmlRoute('refund-policy')),
                )
                    : const TextSpan(),
              ],
            ),
            textAlign: TextAlign.start,
            maxLines: 3,
          ),
        ),
      ],
    );
  }
}
