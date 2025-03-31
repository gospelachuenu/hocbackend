import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/payment_service.dart';
import '../services/supabase_service.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final PaymentService _paymentService = PaymentService();
  final TextEditingController _customAmountController = TextEditingController();
  double _selectedAmount = 0;
  String _selectedPaymentMethod = '';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializePaymentServices();
  }

  Future<void> _initializePaymentServices() async {
    await _paymentService.initializeStripe();
    _paymentService.initializePayPal();
  }

  Future<void> _processPayment() async {
    if (_selectedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter an amount')),
      );
      return;
    }

    if (_selectedPaymentMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final userId = SupabaseService().currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      Map<String, dynamic> result;
      if (_selectedPaymentMethod == 'stripe') {
        result = await _paymentService.processStripePayment(
          amount: _selectedAmount,
          currency: 'gbp',
          description: 'Donation to House of Christ',
        );
      } else if (_selectedPaymentMethod == 'paypal') {
        result = await _paymentService.processPayPalPayment(
          amount: _selectedAmount,
          currency: 'GBP',
          description: 'Donation to House of Christ',
        );
      } else {
        throw Exception('Invalid payment method');
      }

      if (result['success']) {
        await _paymentService.saveTransaction(
          paymentMethod: _selectedPaymentMethod,
          amount: _selectedAmount,
          currency: 'GBP',
          status: 'completed',
          userId: userId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
        }
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Give',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Support Our Ministry',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your generous donation helps us spread the word of God.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Payment Method',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentMethodCard(
              'Credit/Debit Card',
              Icons.credit_card,
              'stripe',
            ),
            const SizedBox(height: 12),
            _buildPaymentMethodCard(
              'PayPal',
              Icons.paypal,
              'paypal',
            ),
            const SizedBox(height: 24),
            Text(
              'Select Amount',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildAmountChip(10),
                _buildAmountChip(20),
                _buildAmountChip(50),
                _buildAmountChip(100),
                _buildCustomAmountChip(),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Donate Now',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(String title, IconData icon, String method) {
    final isSelected = _selectedPaymentMethod == method;
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.red : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedPaymentMethod = method),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32, color: isSelected ? Colors.red : Colors.grey),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const Spacer(),
              if (isSelected)
                const Icon(Icons.check_circle, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountChip(double amount) {
    final isSelected = _selectedAmount == amount;
    return ActionChip(
      label: Text(
        '£${amount.toStringAsFixed(0)}',
        style: GoogleFonts.poppins(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      backgroundColor: isSelected ? Colors.red : Colors.grey[200],
      onPressed: () => setState(() {
        _selectedAmount = amount;
        _customAmountController.clear();
      }),
    );
  }

  Widget _buildCustomAmountChip() {
    return Container(
      width: 120,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _customAmountController,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(),
        decoration: const InputDecoration(
          hintText: 'Custom',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 8),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            setState(() => _selectedAmount = double.tryParse(value) ?? 0);
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }
} 