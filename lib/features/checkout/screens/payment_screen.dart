import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Future<void> _makePayment() async {
    try {
      // 1. Fetch client secret from the backend
      final response = await http.post(
        Uri.parse('https://us-central1-upercart-fd922.cloudfunctions.net/createPaymentIntent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': 20000, 'currency': 'usd'}),
      );
      final jsonResponse = jsonDecode(response.body);

      // 2. Initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: jsonResponse['clientSecret'],
          merchantDisplayName: 'Upercart',
        ),
      );

      // 3. Display the payment sheet
      await Stripe.instance.presentPaymentSheet();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Payment successful')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Payment failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Stripe Payment')),
      body: Center(
        child: ElevatedButton(
          onPressed: _makePayment,
          child: Text('Pay Now'),
        ),
      ),
    );
  }
}
