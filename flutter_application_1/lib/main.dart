import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'edit_profile_screen.dart';
import 'payment_screen.dart';
import 'savings_screen.dart';

// Transaction History Screen
class TransactionHistoryScreen extends StatefulWidget {
  @override
  _TransactionHistoryScreenState createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  String _selectedFilter = 'all';
  bool _isLoading = true;
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  int _transactionCount = 0;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _loadTransactionStats();
  }

  // Migration function to update existing transactions from email to UID
  Future<void> _migrateUserTransactions() async {
    if (_currentUser == null) return;
    
    try {
      // Find transactions with the user's email as userId
      final emailTransactions = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: _currentUser!.email)
          .get();
      
      if (emailTransactions.docs.isNotEmpty) {
        print('Found ${emailTransactions.docs.length} transactions to migrate for user: ${_currentUser!.email}');
        
        // Update each transaction to use UID instead of email
        final batch = _firestore.batch();
        
        for (final doc in emailTransactions.docs) {
          batch.update(doc.reference, {'userId': _currentUser!.uid});
        }
        
        await batch.commit();
        print('Successfully migrated ${emailTransactions.docs.length} transactions to UID');
      }
    } catch (e) {
      print('Error migrating transactions: $e');
    }
  }

  Future<void> _loadTransactionStats() async {
    if (_currentUser == null) return;
    
    try {
      // First, migrate any existing transactions from email to UID
      await _migrateUserTransactions();
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: _currentUser!.uid)
          .get();
      
      double income = 0.0;
      double expenses = 0.0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0).toDouble();
        final type = data['type'] ?? '';
        
        if (type == 'deposit') {
          income += amount;
        } else if (type == 'withdrawal') {
          expenses += amount;
        }
      }
      
      setState(() {
        _totalIncome = income;
        _totalExpenses = expenses;
        _transactionCount = snapshot.docs.length;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading transaction stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Stream<QuerySnapshot> _getFilteredTransactions() {
    if (_currentUser == null) {
      print('DEBUG: Current user is null in transaction history');
      return const Stream.empty();
    }
    
    print('DEBUG: Querying transactions for user: ${_currentUser!.uid}');
    
    Query query = _firestore
        .collection('transactions')
        .where('userId', isEqualTo: _currentUser!.uid);
    
    if (_selectedFilter != 'all') {
      query = query.where('type', isEqualTo: _selectedFilter);
    }
    
    return query.snapshots();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('All Transactions'),
              leading: Radio<String>(
                value: 'all',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: Text('Deposits Only'),
              leading: Radio<String>(
                value: 'deposit',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: Text('Withdrawals Only'),
              leading: Radio<String>(
                value: 'withdrawal',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3E8FF),
      appBar: AppBar(
        title: Text(
          'Transaction History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        elevation: 4,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : Column(
              children: [
                // Statistics Cards
                Container(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(Icons.arrow_downward, color: Colors.green, size: 32),
                                SizedBox(height: 8),
                                Text('Total Income', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                                Text('₱${_totalIncome.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(Icons.arrow_upward, color: Colors.red, size: 32),
                                SizedBox(height: 8),
                                Text('Total Expenses', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                                Text('₱${_totalExpenses.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long, color: Color(0xFF7C3AED), size: 32),
                                SizedBox(height: 8),
                                Text('Total Count', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                                Text('$_transactionCount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Filter Info
                if (_selectedFilter != 'all')
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF7C3AED),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_list, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Showing ${_selectedFilter}s only',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilter = 'all';
                            });
                          },
                          child: Text('Clear Filter', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                
                // Transactions List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _getFilteredTransactions(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
                      }
                      
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text('No transactions found', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                              Text('Start adding transactions to see your history', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final type = data['type'] ?? '';
                          final amount = (data['amount'] ?? 0).toDouble();
                          final description = data['description'] ?? 'No description';
                          final date = data['date'] != null && data['date'] is Timestamp
                              ? (data['date'] as Timestamp).toDate()
                              : DateTime.now();
                          
                          return Card(
                            elevation: 4,
                            margin: EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: type == 'deposit' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  type == 'deposit' ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: type == 'deposit' ? Colors.green : Colors.red,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                description,
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text(
                                    '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    type == 'deposit' ? 'Deposit' : 'Withdrawal',
                                    style: TextStyle(
                                      color: type == 'deposit' ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                '${type == 'deposit' ? '+' : '-'}₱${amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: type == 'deposit' ? Colors.green : Colors.red,
                                ),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// Account Management Screen
class AccountManagementScreen extends StatefulWidget {
  final Function()? onProfileUpdated;
  
  AccountManagementScreen({this.onProfileUpdated});
  
  @override
  _AccountManagementScreenState createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();
  bool _editing = false;
  bool _isLoading = true;
  String? _emailError;
  User? _currentUser;
  String? _profileImageUrl;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      _currentUser = _auth.currentUser;
      if (_currentUser != null) {
        final userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          _nameController.text = userData['name'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _dobController.text = userData['dob'] ?? '';
          _profileImageUrl = userData['profileImageUrl'];
        } else {
          // If no user document exists, use Firebase Auth data
          _nameController.text = _currentUser!.displayName ?? '';
          _emailController.text = _currentUser!.email ?? '';
          // Set sample data for demonstration
          if (_nameController.text.isEmpty) {
            _nameController.text = 'Juan Dela Cruz';
          }
          if (_dobController.text.isEmpty) {
            _dobController.text = '1990-01-15';
          }
        }
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 512,
        maxHeight: 512,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: Color(0xFF7C3AED)),
              title: Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: Color(0xFF7C3AED)),
              title: Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 512,
        maxHeight: 512,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _save() async {
    setState(() { _emailError = null; });
    if (_formKey.currentState!.validate()) {
      if (_emailController.text.contains('@') && _currentUser != null) {
        try {
          Map<String, dynamic> updateData = {
            'name': _nameController.text,
            'email': _emailController.text,
            'dob': _dobController.text,
            'updatedAt': FieldValue.serverTimestamp(),
          };

          // For now, we'll just store the image path as a placeholder
          // In a real app, you'd upload to Firebase Storage
          if (_selectedImage != null) {
            updateData['profileImageUrl'] = _selectedImage!.path;
          }

          // Update Firestore user document
          await _firestore.collection('users').doc(_currentUser!.uid).set(
            updateData,
            SetOptions(merge: true),
          );

          setState(() {
            _editing = false;
            if (_selectedImage != null) {
              _profileImageUrl = _selectedImage!.path;
              _selectedImage = null;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Account details updated successfully!'), backgroundColor: Colors.green),
          );
          
          // Call the callback to refresh parent screen
          if (widget.onProfileUpdated != null) {
            widget.onProfileUpdated!();
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update account: $e'), backgroundColor: Colors.red),
          );
        }
      } else {
        setState(() { _emailError = 'Email must be valid.'; });
      }
    }
  }

  ImageProvider? _getProfileImage() {
    if (_selectedImage != null) {
      if (kIsWeb) {
        // For web, we need to handle images differently
        return NetworkImage(_selectedImage!.path);
      } else {
        return FileImage(File(_selectedImage!.path));
      }
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      if (_profileImageUrl!.startsWith('http')) {
        return NetworkImage(_profileImageUrl!);
      } else {
        if (kIsWeb) {
          return NetworkImage(_profileImageUrl!);
        } else {
          return FileImage(File(_profileImageUrl!));
        }
      }
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(Duration(days: 365 * 25)), // 25 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF7C3AED),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFF3E8FF),
        appBar: AppBar(
          title: Text(
            'Account Management',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          elevation: 4,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Account Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        elevation: 4,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          !_editing
              ? IconButton(
                  icon: Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _editing = true;
                    });
                  },
                )
              : Container(),
        ],
      ),
      backgroundColor: Color(0xFFF3E8FF),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Card
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.white,
                            backgroundImage: _getProfileImage(),
                            child: _getProfileImage() == null
                                ? Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Color(0xFF7C3AED),
                                  )
                                : null,
                          ),
                          if (_editing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _showImageSourceDialog,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Color(0xFF7C3AED), width: 2),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: Color(0xFF7C3AED),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nameController.text.isNotEmpty ? _nameController.text : 'User',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _editing ? 'Edit mode enabled' : 'View mode',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _editing ? 'Tap camera icon to change photo' : 'Tap edit to modify profile',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              
              // Account Details Card
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_circle, color: Color(0xFF7C3AED), size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        enabled: _editing,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person, color: Color(0xFF7C3AED)),
                          filled: true,
                          fillColor: _editing ? Colors.grey[50] : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFF7C3AED)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFF7C3AED), width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        enabled: _editing,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email, color: Color(0xFF7C3AED)),
                          filled: true,
                          fillColor: _editing ? Colors.grey[50] : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFF7C3AED)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFF7C3AED), width: 2),
                          ),
                          errorText: _emailError,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Email must be valid.';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _dobController,
                        enabled: _editing,
                        readOnly: true,
                        onTap: _editing ? () => _selectDate(context) : null,
                        decoration: InputDecoration(
                          labelText: 'Date of Birth',
                          hintText: 'Tap to select date',
                          prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF7C3AED)),
                          suffixIcon: _editing ? Icon(Icons.date_range, color: Color(0xFF7C3AED)) : null,
                          filled: true,
                          fillColor: _editing ? Colors.grey[50] : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFF7C3AED)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFF7C3AED), width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select your date of birth';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      if (_editing)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _save,
                            icon: Icon(Icons.save),
                            label: Text('Save Changes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF7C3AED),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(BankingApp());
}

class BankingApp extends StatefulWidget {
  @override
  _BankingAppState createState() => _BankingAppState();
}

class _BankingAppState extends State<BankingApp> {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'STS MBank',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            brightness: Brightness.light,
            primaryColor: Color(0xFF7C3AED),
            scaffoldBackgroundColor: Color(0xFFF3E8FF),
            cardColor: Colors.white,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF7C3AED),
              elevation: 2,
            ),
            drawerTheme: DrawerThemeData(
              backgroundColor: Colors.white,
            ),
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: Colors.black87),
              bodyMedium: TextStyle(color: Colors.black87),
              bodySmall: TextStyle(color: Colors.grey[600]),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: Color(0xFF7C3AED),
            scaffoldBackgroundColor: Color(0xFF121212),
            cardColor: Color(0xFF1E1E1E),
            appBarTheme: AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Color(0xFFBB86FC),
              elevation: 2,
            ),
            drawerTheme: DrawerThemeData(
              backgroundColor: Color(0xFF1E1E1E),
            ),
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white70),
              bodySmall: TextStyle(color: Colors.grey[400]),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7C3AED),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          themeMode: themeMode,
          home: LoginScreen(),
          routes: {
            '/login': (context) => LoginScreen(),
            '/signup': (context) => SignupScreen(),
            '/dashboard': (context) => DashboardScreen(),
            '/loan-details': (context) => LoanDetailsScreen(),
            '/account-management': (context) => AccountManagementScreen(),
            '/transaction-history': (context) => TransactionHistoryScreen(),
            '/edit-profile': (context) => EditProfileScreen(),
            '/payment': (context) => PaymentScreen(),
            '/savings': (context) => SavingsScreen(),
          },
        );
      },
    );
  }
}

// Loan Details Screen
class LoanDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loan Details'),
        backgroundColor: Color.fromARGB(255, 177, 129, 235),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Color(0xFFF3E8FF),
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Loan Balance',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Outstanding Amount:', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  SizedBox(height: 4),
                  Text('P28,500.00', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red)),
                  SizedBox(height: 12),
                  Text('Status: In Good Standing', style: TextStyle(fontSize: 14, color: Colors.green)),
                  SizedBox(height: 12),
                  Divider(),
                  SizedBox(height: 8),
                  Text('Next Payment Due:', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  SizedBox(height: 4),
                  Text('July 30, 2025', style: TextStyle(fontSize: 16, color: Colors.black)),
                  SizedBox(height: 12),
                  Text('Monthly Payment:', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  SizedBox(height: 4),
                  Text('P2,500.00', style: TextStyle(fontSize: 16, color: Colors.black)),
                ],
              ),
            ),
            SizedBox(height: 32),
            Text('Recent Loan Payments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: <Widget>[
                  _buildLoanPaymentItem('June 18, 2025', 'P2,500.00'),
                  _buildLoanPaymentItem('May 1, 2025', 'P2,500.00'),
                  _buildLoanPaymentItem('April 1, 2025', 'P2,500.00'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanPaymentItem(String date, String amount) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(Icons.payment, color: Colors.purple),
        title: Text('Payment: $amount'),
        subtitle: Text(date),
        trailing: Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _loginError;

  Future<void> _login() async {
    setState(() { _loginError = null; _loading = true; });
    if (_formKey.currentState!.validate()) {
      try {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        Navigator.pushReplacementNamed(context, '/dashboard');
      } on FirebaseAuthException catch (e) {
        String errorMsg;
        switch (e.code) {
          case 'user-not-found':
            errorMsg = 'No user found for that email.';
            break;
          case 'wrong-password':
            errorMsg = 'Incorrect password.';
            break;
          case 'invalid-email':
            errorMsg = 'Email address is not valid.';
            break;
          case 'user-disabled':
            errorMsg = 'This user account has been disabled.';
            break;
          default:
            errorMsg = 'Login failed: ${e.message}';
        }
        setState(() { _loginError = errorMsg; });
      } catch (e) {
        setState(() { _loginError = 'Login failed: ${e.toString()}'; });
      }
    }
    setState(() { _loading = false; });
  }

  Future<void> _loginWithGoogle() async {
    setState(() { _loading = true; _loginError = null; });
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        // Use signInWithPopup for web
        userCredential = await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          setState(() { _loading = false; });
          return;
        }
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      // Save user info to Firestore if not already present
      final user = userCredential.user;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'dob': '', // Google does not provide DOB
            'createdAt': FieldValue.serverTimestamp(),
            'provider': 'google',
          });
        }
      }
      Navigator.pushReplacementNamed(context, '/dashboard');
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMsg = 'Account exists with a different sign-in method.';
          break;
        case 'invalid-credential':
          errorMsg = 'Invalid Google credentials.';
          break;
        case 'user-disabled':
          errorMsg = 'This user account has been disabled.';
          break;
        case 'user-not-found':
          errorMsg = 'No user found for this Google account.';
          break;
        default:
          errorMsg = 'Google sign-in failed: ${e.message}';
      }
      setState(() { _loginError = errorMsg; });
    } catch (e) {
      setState(() { _loginError = 'Google sign-in failed: ${e.toString()}'; });
    }
    setState(() { _loading = false; });
  }

  void _showFAQ(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Theme.of(context).primaryColor),
            SizedBox(width: 8),
            Text(
              'Help & FAQ',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge!.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFAQItem(
                context,
                'How do I create an account?',
                'Tap "Sign Up" below the login form and fill in your details including name, email, password, and date of birth.',
              ),
              _buildFAQItem(
                context,
                'I forgot my password',
                'Click "Forgot password?" below the login form. You will receive instructions to reset your password.',
              ),
              _buildFAQItem(
                context,
                'Can I sign in with Google?',
                'Yes! Use the "Sign in with Google" button for quick access using your Google account.',
              ),
              _buildFAQItem(
                context,
                'Is my data secure?',
                'Yes, we use Firebase security and encryption to protect your personal and financial information.',
              ),
              _buildFAQItem(
                context,
                'App not working?',
                'Try checking your internet connection or restart the app. Contact support if issues persist.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Theme.of(context).primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Theme.of(context).textTheme.bodyLarge!.color,
        ),
      ),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium!.color,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFAQ(context),
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.help_outline, color: Colors.white),
        tooltip: 'Help & FAQ',
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.light 
                ? Icons.dark_mode 
                : Icons.light_mode,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              _BankingAppState.themeNotifier.value = 
                Theme.of(context).brightness == Brightness.light 
                  ? ThemeMode.dark 
                  : ThemeMode.light;
            },
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo above login info
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/stslogo.jpg',
                        height: 80,
                      ),
                    ),
                  ),
                ),
                Text(
                  'LOGIN',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Theme.of(context).cardColor,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.light 
                              ? Colors.grey[50] 
                              : Colors.grey[800],
                            hintText: 'Please enter your email',
                            hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                            prefixIcon: Icon(Icons.email, color: Theme.of(context).primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            errorText: _loginError,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Email must be valid.';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.light 
                              ? Colors.grey[50] 
                              : Colors.grey[800],
                            hintText: 'Please enter password',
                            hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                            prefixIcon: Icon(Icons.lock, color: Theme.of(context).primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24),
                        _loading
                            ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
                            : ElevatedButton(
                                onPressed: _login,
                                child: Text('Login'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  minimumSize: Size(double.infinity, 50),
                                ),
                              ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loginWithGoogle,
                          icon: Icon(Icons.login),
                          label: Text('Sign in with Google'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
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
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Handle forgot password
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Theme.of(context).cardColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text('Forgot Password', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color)),
                        content: Text('Password reset functionality would be implemented here.', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('OK', style: TextStyle(color: Theme.of(context).primaryColor)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text('Forgot password?', style: TextStyle(color: Theme.of(context).primaryColor)),
                ),
                SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: Text(
                    'Don\'t have an account? Sign Up',
                    style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dobController = TextEditingController();
  DateTime? _selectedDate;
  bool _loading = false;
  String? _signupError;
  bool _obscurePassword = true;
  String _passwordStrength = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _signup() async {
    setState(() { _signupError = null; _loading = true; });
    if (_formKey.currentState!.validate()) {
      if (_emailController.text.contains('@') && _passwordController.text.length >= 6) {
        try {
          // Register user with Firebase Auth
          final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          // Save extra user info to Firestore
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'name': _nameController.text,
            'email': _emailController.text,
            'dob': _dobController.text,
            'createdAt': FieldValue.serverTimestamp(),
          });
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Account Created'),
              content: Text('Your account has been created and saved to the database!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  },
                  child: Text('Go to Dashboard'),
                ),
              ],
            ),
          );
        } catch (e) {
          setState(() { _signupError = 'Failed to create user: ' + e.toString(); });
        }
      } else {
        setState(() { _signupError = 'Invalid email or password.'; });
      }
    }
    setState(() { _loading = false; });
  }

  // Example: Read all users from Firestore (for future viewing)
  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  void _checkPasswordStrength(String value) {
    if (value.length < 6) {
      _passwordStrength = 'Too short';
    } else if (value.contains(RegExp(r'[A-Z]')) && value.contains(RegExp(r'[0-9]'))) {
      _passwordStrength = 'Strong';
    } else {
      _passwordStrength = 'Weak';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.light 
                ? Icons.dark_mode 
                : Icons.light_mode,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              _BankingAppState.themeNotifier.value = 
                Theme.of(context).brightness == Brightness.light 
                  ? ThemeMode.dark 
                  : ThemeMode.light;
            },
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20),
                Text(
                  'SIGN UP',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Theme.of(context).cardColor,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
                          decoration: InputDecoration(
                            hintText: 'Please enter your name',
                            hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                            prefixIcon: Icon(Icons.person, color: Theme.of(context).primaryColor),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.light 
                              ? Colors.grey[50] 
                              : Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
                          decoration: InputDecoration(
                            hintText: 'Please enter your email',
                            hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                            prefixIcon: Icon(Icons.email, color: Theme.of(context).primaryColor),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.light 
                              ? Colors.grey[50] 
                              : Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            errorText: _signupError,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Email must be valid.';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          onChanged: _checkPasswordStrength,
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
                          decoration: InputDecoration(
                            hintText: 'Please enter your password',
                            hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                            prefixIcon: Icon(Icons.lock, color: Theme.of(context).primaryColor),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.light 
                              ? Colors.grey[50] 
                              : Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Theme.of(context).primaryColor),
                              onPressed: () {
                                setState(() { _obscurePassword = !_obscurePassword; });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Password strength: $_passwordStrength',
                            style: TextStyle(
                              fontSize: 12,
                              color: _passwordStrength == 'Strong' ? Colors.green : (_passwordStrength == 'Weak' ? Colors.orange : Colors.red),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        GestureDetector(
                          onTap: () async {
                            FocusScope.of(context).unfocus();
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate ?? DateTime(2000, 1, 1),
                              firstDate: DateTime(1900),
                              lastDate: DateTime(DateTime.now().year - 18, 12, 31),
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedDate = picked;
                                _dobController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                              });
                            }
                          },
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: _dobController,
                              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
                              decoration: InputDecoration(
                                hintText: 'Select your date of birth',
                                hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                                prefixIcon: Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                                filled: true,
                                fillColor: Theme.of(context).brightness == Brightness.light 
                                  ? Colors.grey[50] 
                                  : Colors.grey[800],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select your date of birth';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        _loading
                            ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
                            : ElevatedButton(
                                onPressed: _signup,
                                child: Text('Create new Account'),
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
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: Text(
                    'Already Registered? Login',
                    style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  Map<String, dynamic>? _userData;
  double _totalSavings = 0.0;
  double _currentLoanBalance = 0.0;
  bool _isLoading = true;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Migration function to update existing transactions from email to UID
  Future<void> _migrateUserTransactions() async {
    if (_currentUser == null) return;
    
    try {
      // Find transactions with the user's email as userId
      final emailTransactions = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: _currentUser!.email)
          .get();
      
      if (emailTransactions.docs.isNotEmpty) {
        print('Found ${emailTransactions.docs.length} transactions to migrate for user: ${_currentUser!.email}');
        
        // Update each transaction to use UID instead of email
        final batch = _firestore.batch();
        
        for (final doc in emailTransactions.docs) {
          batch.update(doc.reference, {'userId': _currentUser!.uid});
        }
        
        await batch.commit();
        print('Successfully migrated ${emailTransactions.docs.length} transactions to UID');
      }
    } catch (e) {
      print('Error migrating transactions: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      _currentUser = _auth.currentUser;
      if (_currentUser != null) {
        // First, migrate any existing transactions from email to UID
        await _migrateUserTransactions();
        
        // Get user data from Firestore
        final userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
        if (userDoc.exists) {
          _userData = userDoc.data();
          _profileImageUrl = _userData?['profileImageUrl'];
        }
        
        // Calculate total savings from deposits and withdrawals
        final transactionsSnapshot = await _firestore
            .collection('transactions')
            .where('userId', isEqualTo: _currentUser!.uid)
            .get();
            
        double totalDeposits = 0.0;
        double totalWithdrawals = 0.0;
        
        for (var doc in transactionsSnapshot.docs) {
          final data = doc.data();
          final amount = (data['amount'] ?? 0).toDouble();
          final type = data['type'] ?? '';
          
          if (type == 'deposit') {
            totalDeposits += amount;
          } else if (type == 'withdrawal') {
            totalWithdrawals += amount;
          }
        }
        
        _totalSavings = totalDeposits - totalWithdrawals;
        
        // Get loan balance (you can add loan data to Firestore)
        final loanDoc = await _firestore.collection('loans').doc(_currentUser!.uid).get();
        if (loanDoc.exists) {
          _currentLoanBalance = (loanDoc.data()?['balance'] ?? 0).toDouble();
        }
        
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to get profile image
  ImageProvider? _getProfileImage() {
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      if (_profileImageUrl!.startsWith('http')) {
        return NetworkImage(_profileImageUrl!);
      } else {
        if (kIsWeb) {
          return NetworkImage(_profileImageUrl!);
        } else {
          return FileImage(File(_profileImageUrl!));
        }
      }
    }
    return null;
  }

  // Method to reload user data when returning from edit profile
  Future<void> _refreshUserData() async {
    await _loadUserData();
  }

  // Show loan application dialog
  void _showLoanApplicationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.monetization_on, color: Color(0xFF7C3AED)),
            SizedBox(width: 8),
            Text('Loan Application', style: TextStyle(color: Color(0xFF7C3AED))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick & Easy Loan Application',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                '✓ Competitive interest rates\n✓ Flexible repayment terms\n✓ Quick approval process\n✓ No hidden fees',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Loan Options Available',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Personal Loan: ₱10,000 - ₱500,000\nBusiness Loan: ₱25,000 - ₱2,000,000\nHome Loan: ₱100,000 - ₱10,000,000',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Maybe Later', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoon(context, 'Loan Application');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Apply Now!'),
          ),
        ],
      ),
    );
  }

  // Stream of transactions for the current user (limited to recent 5)
  Stream<QuerySnapshot> _userTransactionsStream() {
    if (_currentUser == null) return const Stream.empty();
    
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: _currentUser!.uid)
        .limit(5)
        .snapshots();
  }

  // Add a transaction with user input
  Future<void> _addTransaction(BuildContext context) async {
    if (_currentUser == null) return;
    
    final _formKey = GlobalKey<FormState>();
    String type = 'deposit';
    String description = '';
    double amount = 0;
    DateTime? selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          backgroundColor: Color(0xFFF3E8FF),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Add Transaction', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: type,
                          items: [
                            DropdownMenuItem(value: 'deposit', child: Row(children: [Icon(Icons.arrow_downward, color: Colors.green), SizedBox(width: 8), Text('Deposit')])),
                            DropdownMenuItem(value: 'withdrawal', child: Row(children: [Icon(Icons.arrow_upward, color: Colors.red), SizedBox(width: 8), Text('Withdrawal')]))
                          ],
                          onChanged: (val) { setState(() { type = val!; }); },
                          decoration: InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            prefixIcon: Icon(Icons.attach_money),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Enter amount';
                            if (double.tryParse(val) == null) return 'Enter valid number';
                            return null;
                          },
                          onChanged: (val) { amount = double.tryParse(val) ?? 0; },
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Description',
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (val) { description = val; },
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Color(0xFF7C3AED)),
                            SizedBox(width: 8),
                            Text('Date:', style: TextStyle(fontWeight: FontWeight.w500)),
                            SizedBox(width: 8),
                            Text(selectedDate != null
                                ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                                : ''),
                            Spacer(),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Color(0xFF7C3AED),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text('Pick Date'),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) setState(() { selectedDate = picked; });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () { Navigator.pop(context); },
                              style: TextButton.styleFrom(
                                foregroundColor: Color(0xFF7C3AED),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text('Cancel'),
                            ),
                            SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  await _firestore.collection('transactions').add({
                                    'userId': _currentUser!.uid,
                                    'type': type,
                                    'amount': amount,
                                    'date': selectedDate != null ? Timestamp.fromDate(selectedDate!) : FieldValue.serverTimestamp(),
                                    'description': description,
                                  });
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Transaction added!')),
                                  );
                                  // Reload user data to update balances
                                  _loadUserData();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: type == 'deposit' ? Colors.green : Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                elevation: 4,
                              ),
                              child: Text('Add'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ...existing code...

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('This feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _auth.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDashboardFAQ(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Theme.of(context).primaryColor),
            SizedBox(width: 8),
            Text(
              'Banking Help & FAQ',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge!.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDashboardFAQItem(
                context,
                'How do I add money to my account?',
                'Use the "Add Money" button in Quick Actions or click the "Add Transaction" button in Recent Activity to deposit funds.',
              ),
              _buildDashboardFAQItem(
                context,
                'How do I check my savings?',
                'Click on the "Total Savings" card or use the "Savings" option in the drawer menu to view your savings details and goals.',
              ),
              _buildDashboardFAQItem(
                context,
                'How do I apply for a loan?',
                'Click on the "Loan Balance" card to apply for a new loan or manage existing ones. Follow the application process.',
              ),
              _buildDashboardFAQItem(
                context,
                'How do I view my transaction history?',
                'Use the "History" button in Quick Actions or select "Transaction History" from the drawer menu.',
              ),
              _buildDashboardFAQItem(
                context,
                'How do I pay bills?',
                'Click "Pay Bills" in Quick Actions or select "Pay Bills/Loans" from the drawer menu to make payments.',
              ),
              _buildDashboardFAQItem(
                context,
                'How do I update my profile?',
                'Click the person icon in the top-right corner to access and edit your account information.',
              ),
              _buildDashboardFAQItem(
                context,
                'How do I switch themes?',
                'Click the moon/sun icon in the top-right corner to toggle between light and dark themes.',
              ),
              _buildDashboardFAQItem(
                context,
                'Is my money safe?',
                'Yes! We use bank-level security, encryption, and Firebase authentication to protect your funds and personal information.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Theme.of(context).primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardFAQItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Theme.of(context).textTheme.bodyLarge!.color,
        ),
      ),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium!.color,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFF3E8FF),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        ),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: Color(0xFFF3E8FF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Please log in to continue', style: TextStyle(fontSize: 18)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    final String userName = _userData?['name'] ?? _currentUser!.displayName ?? 'User';
    final String userEmail = _currentUser!.email ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDashboardFAQ(context),
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.help_outline, color: Colors.white),
        tooltip: 'Banking Help & FAQ',
      ),
      drawer: Drawer(
        backgroundColor: Theme.of(context).drawerTheme.backgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFBB86FC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              accountName: Text(userName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              accountEmail: Text(userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: _getProfileImage(),
                child: _getProfileImage() == null
                    ? Icon(Icons.person, color: Color(0xFF7C3AED), size: 28)
                    : null,
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard, color: Theme.of(context).primaryColor),
              title: Text('Dashboard', style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge!.color)),
              onTap: () { Navigator.pop(context); },
            ),
            ListTile(
              leading: Icon(Icons.account_balance_wallet, color: Theme.of(context).primaryColor),
              title: Text('My Accounts', style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge!.color)),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AccountManagementScreen(
                      onProfileUpdated: _refreshUserData,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history, color: Theme.of(context).primaryColor),
              title: Text('Transaction History', style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge!.color)),
              onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/transaction-history'); },
            ),
            ListTile(
              leading: Icon(Icons.money, color: Theme.of(context).primaryColor),
              title: Text('Loans', style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge!.color)),
              onTap: () { 
                Navigator.pop(context); 
                _showLoanApplicationDialog(); 
              },
            ),
            ListTile(
              leading: Icon(Icons.savings, color: Theme.of(context).primaryColor),
              title: Text('Savings', style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge!.color)),
              onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/savings'); },
            ),
            ListTile(
              leading: Icon(Icons.payment, color: Theme.of(context).primaryColor),
              title: Text('Pay Bills/Loans', style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge!.color)),
              onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/payment'); },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
              onTap: () { Navigator.pop(context); _showLogoutDialog(context); },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.2),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Theme.of(context).primaryColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text('STS MBank', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.person_outline, color: Theme.of(context).primaryColor),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AccountManagementScreen(
                    onProfileUpdated: _refreshUserData,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Theme.of(context).primaryColor),
            onPressed: () { _showComingSoon(context, 'Notifications'); },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).primaryColor),
            onPressed: () { _loadUserData(); },
          ),
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.light 
                ? Icons.dark_mode 
                : Icons.light_mode, 
              color: Theme.of(context).primaryColor
            ),
            onPressed: () {
              _BankingAppState.themeNotifier.value = 
                Theme.of(context).brightness == Brightness.light 
                  ? ThemeMode.dark 
                  : ThemeMode.light;
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Welcome Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFCDB4DB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), spreadRadius: 2, blurRadius: 8)],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back, $userName', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 28,
                    backgroundImage: _getProfileImage(),
                    child: _getProfileImage() == null
                        ? Icon(Icons.person, color: Color(0xFF7C3AED), size: 32)
                        : null,
                  ),
                ],
              ),
            ),
            // Balance Cards
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Make cards stack vertically on mobile instead of side by side
                      Column(
                        children: [
                          // Total Savings Card
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/savings');
                            },
                            child: Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              color: Theme.of(context).cardColor,
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(Icons.savings, color: Colors.green, size: 28),
                                    SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total Savings', 
                                          style: TextStyle(
                                            fontSize: 14, 
                                            color: Theme.of(context).textTheme.bodyMedium!.color, 
                                            fontWeight: FontWeight.w600
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '₱${_totalSavings.toStringAsFixed(2)}', 
                                          style: TextStyle(
                                            fontSize: 24, 
                                            fontWeight: FontWeight.bold, 
                                            color: _totalSavings >= 0 ? Colors.green : Colors.red
                                          )
                                        ),
                                        Text(
                                          'Current balance', 
                                          style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall!.color)
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).textTheme.bodySmall!.color),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        // Loan Balance Card
                        GestureDetector(
                          onTap: () {
                            if (_currentLoanBalance == 0) {
                              _showLoanApplicationDialog();
                            } else {
                              Navigator.pushNamed(context, '/loan-details');
                            }
                          },
                          child: Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            color: Theme.of(context).cardColor,
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.money, color: Colors.red, size: 28),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Loan Balance', 
                                              style: TextStyle(
                                                fontSize: 14, 
                                                color: Theme.of(context).textTheme.bodyMedium!.color, 
                                                fontWeight: FontWeight.w600
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              '₱${_currentLoanBalance.toStringAsFixed(2)}', 
                                              style: TextStyle(
                                                fontSize: 24, 
                                                fontWeight: FontWeight.bold, 
                                                color: _currentLoanBalance > 0 ? Colors.red : Colors.green
                                              )
                                            ),
                                            Text(
                                              _currentLoanBalance > 0 ? 'Outstanding' : 'No active loans', 
                                              style: TextStyle(
                                                fontSize: 12, 
                                                color: _currentLoanBalance > 0 ? Colors.red : Colors.green
                                              )
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // Add persuasive call-to-action section - mobile optimized
                                  if (_currentLoanBalance == 0) ...[
                                    SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xFF7C3AED).withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.trending_up, color: Colors.white, size: 16),
                                              SizedBox(width: 6),
                                              Text(
                                                'Need funds?',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Apply for a loan now!',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Starting from ₱10,000',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blue[200]!),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.add_circle_outline, color: Colors.blue[700], size: 16),
                                              SizedBox(width: 6),
                                              Text(
                                                'Need more?',
                                                style: TextStyle(
                                                  color: Colors.blue[700],
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Apply for additional loan!',
                                            style: TextStyle(
                                              color: Colors.blue[700],
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Quick approval available',
                                            style: TextStyle(
                                              color: Colors.blue[500],
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Quick Actions
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Theme.of(context).cardColor,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.flash_on, color: Theme.of(context).primaryColor),
                                SizedBox(width: 8),
                                Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge!.color)),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildQuickActionButton(
                                  icon: Icons.add_circle,
                                  label: 'Add Money',
                                  color: Colors.green,
                                  onTap: () => _addTransaction(context),
                                ),
                                _buildQuickActionButton(
                                  icon: Icons.savings,
                                  label: 'Savings',
                                  color: Colors.blue,
                                  onTap: () => Navigator.pushNamed(context, '/savings'),
                                ),
                                _buildQuickActionButton(
                                  icon: Icons.payment,
                                  label: 'Pay Bills',
                                  color: Colors.orange,
                                  onTap: () => Navigator.pushNamed(context, '/payment'),
                                ),
                                _buildQuickActionButton(
                                  icon: Icons.history,
                                  label: 'History',
                                  color: Colors.purple,
                                  onTap: () => Navigator.pushNamed(context, '/transaction-history'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Account Activity
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Theme.of(context).cardColor,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.history, color: Theme.of(context).primaryColor),
                                    SizedBox(width: 8),
                                    Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge!.color)),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () { Navigator.pushNamed(context, '/transaction-history'); },
                                  child: Text('View All', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            // Add Transaction button - mobile optimized
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () { _addTransaction(context); },
                                icon: Icon(Icons.add, color: Colors.white),
                                label: Text('Add Transaction'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            SizedBox(height: 18),
                            // Transaction items from Firestore
                            StreamBuilder<QuerySnapshot>(
                              stream: _userTransactionsStream(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Container(
                                    padding: EdgeInsets.all(24),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                
                                if (snapshot.hasError) {
                                  return Container(
                                    padding: EdgeInsets.all(24),
                                    child: Column(
                                      children: [
                                        Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                                        SizedBox(height: 12),
                                        Text('Error loading transactions', style: TextStyle(fontSize: 16, color: Colors.red[600], fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  );
                                }
                                
                                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                  return Container(
                                    padding: EdgeInsets.all(24),
                                    child: Column(
                                      children: [
                                        Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                                        SizedBox(height: 12),
                                        Text('No transactions yet', style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                                        SizedBox(height: 4),
                                        Text('Add transactions to see them here', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                                      ],
                                    ),
                                  );
                                }
                                
                                final transactions = snapshot.data!.docs;
                                return Column(
                                  children: transactions.map((doc) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    final amount = (data['amount'] ?? 0).toDouble();
                                    final type = data['type'] ?? 'deposit';
                                    final description = data['description'] ?? 'No description';
                                    final dateField = data['date'] ?? data['timestamp'];
                                    final date = dateField is Timestamp ? dateField.toDate() : DateTime.now();
                                    
                                    // Format date more nicely
                                    final now = DateTime.now();
                                    final today = DateTime(now.year, now.month, now.day);
                                    final yesterday = today.subtract(Duration(days: 1));
                                    final transactionDate = DateTime(date.year, date.month, date.day);
                                    
                                    String dateStr;
                                    if (transactionDate == today) {
                                      dateStr = 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                                    } else if (transactionDate == yesterday) {
                                      dateStr = 'Yesterday at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                                    } else {
                                      dateStr = '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                                    }
                                    
                                    return Card(
                                      margin: EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: type == 'deposit' ? Colors.green[100] : Colors.red[100],
                                          child: Icon(
                                            type == 'deposit' ? Icons.arrow_downward : Icons.arrow_upward,
                                            color: type == 'deposit' ? Colors.green : Colors.red,
                                          ),
                                        ),
                                        title: Text(description, style: TextStyle(fontWeight: FontWeight.w600)),
                                        subtitle: Text(
                                          dateStr,
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                        trailing: Text(
                                          '${type == 'deposit' ? '+' : '-'}₱${amount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: type == 'deposit' ? Colors.green : Colors.red,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Financial Insights
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Theme.of(context).cardColor,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.insights, color: Theme.of(context).primaryColor),
                                SizedBox(width: 8),
                                Text('Financial Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge!.color)),
                              ],
                            ),
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Theme.of(context).primaryColor.withOpacity(0.1), Theme.of(context).primaryColor.withOpacity(0.2)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '💡 Smart Tip',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _totalSavings > 0 
                                      ? 'Great job! You\'re building your savings. Consider setting up automatic transfers to reach your goals faster.'
                                      : 'Start your savings journey today! Even small amounts can grow significantly over time.',
                                    style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall!.color),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ), // Column closing
              ), // Padding closing
            ), // SingleChildScrollView closing
          ), // Expanded closing
          ], // Column children closing
        ), // Column closing (main Column)
      ), // SafeArea closing
    );
  }
}

