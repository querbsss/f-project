import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SavingsScreen extends StatefulWidget {
  @override
  _SavingsScreenState createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  bool _isLoading = true;
  
  // Savings data
  double _totalSavings = 0.0;
  double _monthlyTarget = 5000.0;
  double _yearlyTarget = 60000.0;
  double _currentMonthSavings = 0.0;
  double _currentYearSavings = 0.0;
  
  // Savings accounts
  List<Map<String, dynamic>> _savingsAccounts = [];
  
  @override
  void initState() {
    super.initState();
    _loadSavingsData();
  }

  Future<void> _loadSavingsData() async {
    try {
      _currentUser = _auth.currentUser;
      if (_currentUser != null) {
        //savings targets
        final userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          _monthlyTarget = (userData?['monthlyTarget'] ?? 5000.0).toDouble();
          _yearlyTarget = (userData?['yearlyTarget'] ?? 60000.0).toDouble();
        }
        
        // Calculate total savings from transactions
        final transactionsSnapshot = await _firestore
            .collection('transactions')
            .where('userId', isEqualTo: _currentUser!.uid)
            .get();
            
        double totalDeposits = 0.0;
        double totalWithdrawals = 0.0;
        double monthlyDeposits = 0.0;
        double yearlyDeposits = 0.0;
        
        final now = DateTime.now();
        final currentMonth = DateTime(now.year, now.month);
        final currentYear = DateTime(now.year);
        
        for (var doc in transactionsSnapshot.docs) {
          final data = doc.data();
          final amount = (data['amount'] ?? 0).toDouble();
          final type = data['type'] ?? '';
          final timestamp = data['date'] as Timestamp?;
          final date = timestamp?.toDate() ?? DateTime.now();
          
          if (type == 'deposit') {
            totalDeposits += amount;
            
            // Monthly savings
            if (date.isAfter(currentMonth.subtract(Duration(days: 1)))) {
              monthlyDeposits += amount;
            }
            
            // Yearly savings
            if (date.isAfter(currentYear.subtract(Duration(days: 1)))) {
              yearlyDeposits += amount;
            }
          } else if (type == 'withdrawal') {
            totalWithdrawals += amount;
          }
        }
        
        _totalSavings = totalDeposits - totalWithdrawals;
        _currentMonthSavings = monthlyDeposits;
        _currentYearSavings = yearlyDeposits;
        
        // Load savings accounts (mock data for now)
        _savingsAccounts = [
          {
            'name': 'Regular Savings',
            'balance': _totalSavings * 0.7,
            'interestRate': 2.5,
            'type': 'regular',
            'icon': Icons.savings,
            'color': Colors.green,
          },
          {
            'name': 'High-Yield Savings',
            'balance': _totalSavings * 0.2,
            'interestRate': 4.2,
            'type': 'high_yield',
            'icon': Icons.trending_up,
            'color': Colors.blue,
          },
          {
            'name': 'Emergency Fund',
            'balance': _totalSavings * 0.1,
            'interestRate': 3.0,
            'type': 'emergency',
            'icon': Icons.security,
            'color': Colors.orange,
          },
        ];
        
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading savings data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSetTargetDialog() {
    final monthlyController = TextEditingController(text: _monthlyTarget.toString());
    final yearlyController = TextEditingController(text: _yearlyTarget.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.flag, color: Theme.of(context).primaryColor),
            SizedBox(width: 8),
            Text(
              'Set Savings Goals', 
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge!.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: monthlyController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
              decoration: InputDecoration(
                labelText: 'Monthly Target (₱)',
                labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light 
                  ? Colors.grey[50] 
                  : Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.calendar_month, color: Theme.of(context).primaryColor),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: yearlyController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
              decoration: InputDecoration(
                labelText: 'Yearly Target (₱)',
                labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light 
                  ? Colors.grey[50] 
                  : Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final monthly = double.tryParse(monthlyController.text) ?? _monthlyTarget;
              final yearly = double.tryParse(yearlyController.text) ?? _yearlyTarget;
              
              await _firestore.collection('users').doc(_currentUser!.uid).update({
                'monthlyTarget': monthly,
                'yearlyTarget': yearly,
              });
              
              setState(() {
                _monthlyTarget = monthly;
                _yearlyTarget = yearly;
              });
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Savings goals updated!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCreateAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.add_circle, color: Theme.of(context).primaryColor),
            SizedBox(width: 8),
            Text(
              'Create Savings Account', 
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge!.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'This feature allows you to create specialized savings accounts like:\n\n• Goal-based savings (vacation, car, house)\n• Time deposits with fixed rates\n• Retirement savings accounts\n• Children\'s education funds\n\nWould you like to enable this feature?',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium!.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Maybe Later',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Coming soon! Stay tuned for more savings options.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Enable'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(String title, double current, double target, Color color) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge!.color),
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₱${current.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
                ),
                Text(
                  '₱${target.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium!.color),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              '${(progress * 100).toStringAsFixed(1)}% achieved',
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall!.color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsAccountCard(Map<String, dynamic> account) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: account['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(account['icon'], color: account['color'], size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account['name'],
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${account['interestRate']}% APY',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '₱${account['balance'].toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: account['color'],
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Interest: ₱${(account['balance'] * account['interestRate'] / 100 / 12).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Savings', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Savings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.flag),
            onPressed: _showSetTargetDialog,
            tooltip: 'Set Goals',
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showCreateAccountDialog,
            tooltip: 'Create Account',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Savings Overview
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.savings, color: Colors.white, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Total Savings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      '₱${_totalSavings.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Across all savings accounts',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Savings Goals Progress
            Text(
              'Savings Goals',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            SizedBox(height: 12),
            
            _buildProgressIndicator(
              'Monthly Goal',
              _currentMonthSavings,
              _monthlyTarget,
              Colors.green,
            ),
            
            SizedBox(height: 12),
            
            _buildProgressIndicator(
              'Yearly Goal',
              _currentYearSavings,
              _yearlyTarget,
              Colors.blue,
            ),
            
            SizedBox(height: 20),
            
            // Savings Accounts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Savings Accounts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                ),
                TextButton.icon(
                  onPressed: _showCreateAccountDialog,
                  icon: Icon(Icons.add, color: Color(0xFF7C3AED)),
                  label: Text('Add New', style: TextStyle(color: Color(0xFF7C3AED))),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            // Savings Account Cards
            ..._savingsAccounts.map((account) => Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: _buildSavingsAccountCard(account),
            )),
            
            SizedBox(height: 20),
            
            // Savings Tips
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.amber, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Savings Tips',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge!.color),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '• Set up automatic transfers to your savings account\n'
                      '• Use the 50/30/20 rule: 50% needs, 30% wants, 20% savings\n'
                      '• Take advantage of compound interest with high-yield accounts\n'
                      '• Review and adjust your goals regularly\n'
                      '• Consider different savings accounts for different goals',
                      style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium!.color),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
