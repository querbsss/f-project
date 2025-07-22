import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme_manager.dart';

class CustomerSupportScreen extends StatelessWidget {
  const CustomerSupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.2),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          child: Image.asset(
            'assets/stslogo.jpg',
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.light 
                ? Icons.dark_mode 
                : Icons.light_mode, 
              color: Theme.of(context).primaryColor
            ),
            onPressed: () {
              ThemeManager.themeNotifier.value = 
                Theme.of(context).brightness == Brightness.light 
                  ? ThemeMode.dark 
                  : ThemeMode.light;
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFCDB4DB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      spreadRadius: 2,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.support_agent,
                      size: 48,
                      color: Colors.white,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Customer Support',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'We\'re here to help you 24/7',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Quick Contact Methods
              _buildSectionCard(
                context,
                title: 'Contact Us',
                icon: Icons.contact_support,
                children: [
                  _buildContactMethod(
                    context,
                    icon: Icons.phone,
                    title: 'Call Us',
                    subtitle: '+63 (2) 8888-BANK (2265)',
                    description: 'Available 24/7 for urgent matters',
                    color: Colors.green,
                    onTap: () => _makePhoneCall('+6328888BANK'),
                  ),
                  SizedBox(height: 12),
                  _buildContactMethod(
                    context,
                    icon: Icons.email,
                    title: 'Email Support',
                    subtitle: 'support@mbank.ph',
                    description: 'Response within 24 hours',
                    color: Colors.blue,
                    onTap: () => _sendEmail('support@mbank.ph'),
                  ),
                  SizedBox(height: 12),
                  _buildContactMethod(
                    context,
                    icon: Icons.chat,
                    title: 'Live Chat',
                    subtitle: 'Chat with our agents',
                    description: 'Available Mon-Fri 8AM-8PM',
                    color: Colors.purple,
                    onTap: () => _showComingSoon(context, 'Live Chat'),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Emergency Support
              _buildSectionCard(
                context,
                title: 'Emergency Support',
                icon: Icons.emergency,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Lost or Stolen Card?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _makePhoneCall('+6328888BANK'),
                                icon: Icon(Icons.phone, size: 18),
                                label: Text('Call Now'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showCardBlockDialog(context),
                                icon: Icon(Icons.block, size: 18),
                                label: Text('Block Card'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Help Categories
              _buildSectionCard(
                context,
                title: 'Help Categories',
                icon: Icons.help_center,
                children: [
                  _buildHelpCategory(
                    context,
                    icon: Icons.account_balance_wallet,
                    title: 'Account & Banking',
                    items: [
                      'Account balance inquiries',
                      'Transaction history',
                      'Account settings',
                      'Password reset',
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildHelpCategory(
                    context,
                    icon: Icons.credit_card,
                    title: 'Cards & Payments',
                    items: [
                      'Card activation',
                      'Payment issues',
                      'ATM locations',
                      'Transaction disputes',
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildHelpCategory(
                    context,
                    icon: Icons.money,
                    title: 'Loans & Credit',
                    items: [
                      'Loan applications',
                      'Payment schedules',
                      'Interest rates',
                      'Credit inquiries',
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildHelpCategory(
                    context,
                    icon: Icons.security,
                    title: 'Security & Privacy',
                    items: [
                      'Account security',
                      'Fraud protection',
                      'Privacy settings',
                      'Suspicious activity',
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Quick Actions
              _buildSectionCard(
                context,
                title: 'Quick Actions',
                icon: Icons.speed,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionButton(
                          context,
                          icon: Icons.location_on,
                          label: 'Find ATM',
                          color: Colors.orange,
                          onTap: () => _showComingSoon(context, 'ATM Locator'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionButton(
                          context,
                          icon: Icons.rate_review,
                          label: 'Feedback',
                          color: Colors.teal,
                          onTap: () => _showFeedbackDialog(context),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionButton(
                          context,
                          icon: Icons.article,
                          label: 'User Guide',
                          color: Colors.indigo,
                          onTap: () => _showComingSoon(context, 'User Guide'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionButton(
                          context,
                          icon: Icons.schedule,
                          label: 'Business Hours',
                          color: Colors.brown,
                          onTap: () => _showBusinessHours(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: 24),
              
              // Footer
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'MBank (Beta)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your trusted banking partner',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium!.color,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Version 1.0.0 (Beta) • Last updated: July 2025',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall!.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
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
                Icon(icon, color: Theme.of(context).primaryColor),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildContactMethod(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall!.color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCategory(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium!.color,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
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

  // Utility methods
  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  void _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=MBank Support Request',
    );
    await launchUrl(launchUri);
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  void _showCardBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Block Card'),
          ],
        ),
        content: Text(
          'Are you sure you want to block your card? This action will prevent all transactions until you contact support to unblock it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoon(context, 'Card Blocking');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Block Card'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final TextEditingController feedbackController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.rate_review, color: Theme.of(context).primaryColor),
            SizedBox(width: 8),
            Text('Send Feedback'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Help us improve MBank! Share your thoughts and suggestions.'),
            SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your feedback here...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Copy feedback to clipboard
              Clipboard.setData(ClipboardData(text: feedbackController.text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Feedback copied to clipboard! Please email it to support@mbank.ph'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showBusinessHours(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.schedule, color: Theme.of(context).primaryColor),
            SizedBox(width: 8),
            Text('Business Hours'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBusinessHourItem('Customer Support', 'Mon-Fri: 8:00 AM - 8:00 PM'),
            _buildBusinessHourItem('Emergency Line', '24/7 Available'),
            _buildBusinessHourItem('Branch Banking', 'Mon-Fri: 9:00 AM - 5:00 PM'),
            _buildBusinessHourItem('Saturday', '9:00 AM - 2:00 PM'),
            _buildBusinessHourItem('Sunday & Holidays', 'Closed'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessHourItem(String service, String hours) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            service,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            hours,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
