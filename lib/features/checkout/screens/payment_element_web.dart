import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_stripe_web/flutter_stripe_web.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:web/web.dart' as web;

String getUrlPort() => web.window.location.port;

String getReturnUrl() => "";

Future<bool> pay() async {
  try {
    final result = await WebStripe.instance.confirmPaymentElement(
      ConfirmPaymentElementOptions(
        confirmParams: ConfirmPaymentParams(return_url: getReturnUrl()),
        redirect: PaymentConfirmationRedirect.ifRequired
      ),
    );

    if (result.status==PaymentIntentsStatus.Succeeded){
      return true;
    }else{
      showCustomSnackBar("Error occured while processing payment");
      return false;
    }
  } catch (error) {
    showCustomSnackBar("Error occured while processing payment");
    return false;
  }
}

class PlatformPaymentElement extends StatelessWidget {
  const PlatformPaymentElement(this.clientSecret);

  final String? clientSecret;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: PaymentElement(
        autofocus: true,
        enablePostalCode: true,
        onCardChanged: (_) {},
        clientSecret: clientSecret ?? '',
      ),
    );
  }
}
