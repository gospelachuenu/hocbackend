import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_paypal_sdk/flutter_paypal_sdk.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  // Railway backend URL
  final String _backendUrl = dotenv.env['RAILWAY_BACKEND_URL'] ?? '';
  
  // Initialize Stripe
  Future<void> initializeStripe() async {
    Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
    await Stripe.instance.applySettings();
  }

  // Initialize PayPal
  late FlutterPaypalSDK _paypalClient;
  
  void initializePayPal() {
    _paypalClient = FlutterPaypalSDK(
      clientId: dotenv.env['PAYPAL_CLIENT_ID'] ?? '',
      clientSecret: dotenv.env['PAYPAL_CLIENT_SECRET'] ?? '',
      mode: dotenv.env['PAYPAL_MODE'] == 'live' 
          ? PayPalEnvironment.live 
          : PayPalEnvironment.sandbox,
    );
  }

  // Process Stripe Payment
  Future<Map<String, dynamic>> processStripePayment({
    required double amount,
    required String currency,
    required String description,
  }) async {
    try {
      // Create payment intent on backend
      final response = await http.post(
        Uri.parse('$_backendUrl/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'amount': (amount * 100).toInt(), // Convert to cents
          'currency': currency,
          'description': description,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create payment intent');
      }

      final paymentIntent = json.decode(response.body);

      // Confirm payment with Stripe SDK
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['clientSecret'],
          merchantDisplayName: 'House of Christ',
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      // Payment successful
      return {'success': true, 'message': 'Payment successful'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Process PayPal Payment
  Future<Map<String, dynamic>> processPayPalPayment({
    required double amount,
    required String currency,
    required String description,
  }) async {
    try {
      final order = PayPalOrder(
        intent: PayPalOrderIntent.CAPTURE,
        purchaseUnits: [
          PurchaseUnit(
            amount: Amount(
              currencyCode: currency,
              value: amount.toString(),
            ),
            description: description,
          ),
        ],
        userAction: UserAction.PAY_NOW,
      );

      final result = await _paypalClient.createOrder(order);
      
      // Verify payment on backend
      final verificationResponse = await http.post(
        Uri.parse('$_backendUrl/verify-paypal-payment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'orderId': result.id,
          'amount': amount,
          'currency': currency,
        }),
      );

      if (verificationResponse.statusCode != 200) {
        throw Exception('Failed to verify PayPal payment');
      }

      return {'success': true, 'message': 'Payment successful'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Save transaction to database
  Future<void> saveTransaction({
    required String paymentMethod,
    required double amount,
    required String currency,
    required String status,
    required String userId,
  }) async {
    try {
      await http.post(
        Uri.parse('$_backendUrl/save-transaction'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'paymentMethod': paymentMethod,
          'amount': amount,
          'currency': currency,
          'status': status,
          'userId': userId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      print('Error saving transaction: $e');
    }
  }
} 