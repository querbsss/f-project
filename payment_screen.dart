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
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text(
                'Payment Successful',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Your payment of ₱${_amountController.text} has been sent to ${_recipientController.text}.',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium!.color,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
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
        title: Text(
          'Make a Payment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Enter Payment Details', 
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                ),
              ),
              SizedBox(height: 24),
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                          prefixText: '₱',
                          prefixStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.light 
                            ? Colors.grey[50] 
                            : Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          errorText: _amountError,
                          prefixIcon: Icon(Icons.attach_money, color: Theme.of(context).primaryColor),
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
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
                        decoration: InputDecoration(
                          labelText: 'Recipient',
                          labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.light 
                            ? Colors.grey[50] 
                            : Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          errorText: _recipientError,
                          prefixIcon: Icon(Icons.person, color: Theme.of(context).primaryColor),
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
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
                        decoration: InputDecoration(
                          labelText: 'Note (optional)',
                          labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.light 
                            ? Colors.grey[50] 
                            : Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.note, color: Theme.of(context).primaryColor),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitPayment,
                child: Text('Send Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
