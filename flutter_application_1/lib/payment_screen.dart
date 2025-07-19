import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _recipientController = TextEditingController();
  final _noteController = TextEditingController();

  String? _amountError;
  String? _recipientError;
  void _submitPayment() {
    setState(() {
      _amountError = null;
      _recipientError = null;
    });
    bool valid = true;
    final amountText = _amountController.text;
    final recipientText = _recipientController.text;
    final num? amount = num.tryParse(amountText);
    if (amountText.isEmpty || amount == null || amount <= 0) {
      setState(() { _amountError = 'Enter a valid amount'; });
      valid = false;
    }
    if (recipientText.isEmpty) {
      setState(() { _recipientError = 'Please enter a recipient'; });
      valid = false;
    }
    if (valid && _formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Payment Successful'),
          content: Text('Your payment of ₱${_amountController.text} has been sent to ${_recipientController.text}.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Make a Payment'),
        backgroundColor: Color.fromARGB(255, 157, 109, 214),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Color(0xFFF3E8FF),
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Enter Payment Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₱',
                  border: OutlineInputBorder(),
                  errorText: _amountError,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final num? amount = num.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _recipientController,
                decoration: InputDecoration(
                  labelText: 'Recipient',
                  border: OutlineInputBorder(),
                  errorText: _recipientError,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a recipient';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitPayment,
                child: Text('Send Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFbb86fc),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
