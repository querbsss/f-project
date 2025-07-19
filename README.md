# STS MBank - Mobile Banking Application

A modern, secure mobile banking application built with Flutter and Firebase. STS MBank provides users with a comprehensive digital banking experience including account management, transaction tracking, savings goals, and loan applications.

Features

 Authentication & Security
- **Email/Password Authentication** - Secure login with Firebase Auth
- **Google Sign-In Integration** - Quick access with Google accounts
- **Demo Mode** - Try the app without creating an account
- **User Profile Management** - Update personal information and profile photos

Banking Core Features
- **Account Dashboard** - Real-time balance and account overview
- **Transaction Management** - Add deposits and withdrawals
- **Transaction History** - View and filter all transactions
- **Savings Tracking** - Monitor savings goals and progress
- **Loan Applications** - Apply for personal, business, and home loans
- **Bill Payments** - Pay bills and manage loan payments

User Experience
- **Dark/Light Theme** - Toggle between themes
- **Responsive Design** - Works on various screen sizes
- **Real-time Updates** - Live data synchronization
- **Interactive Help** - Built-in FAQ and help system
- **Clean UI** - Modern Material Design interface

Technology Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase
  - Authentication (Firebase Auth)
  - Database (Cloud Firestore)
  - Real-time Sync
- **State Management**: StatefulWidget
- **Image Handling**: Image Picker
- **Platform Support**: Android, iOS, Web




Getting Started

Prerequisites
- Flutter SDK (3.0 or higher)
- Dart SDK
- Firebase project setup
- Android Studio / VS Code
- Git

(Installation)

1. Clone the repository
   ```bash
   git clone https://github.com/querbsss/f-project.git
   cd f-project/sts_mbank_new
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Firebase Setup
   - Create a new Firebase project
   - Enable Authentication (Email/Password and Google)
   - Enable Cloud Firestore
   - Download and place `google-services.json` in `android/app/`
   - Update `firebase_options.dart` with your config

4. Run the application
   ```bash
   flutter run
   ```

Project Structure

```
lib/
├── main.dart                 # Main app entry point
├── firebase_options.dart     # Firebase configuration
├── edit_profile_screen.dart  # Profile editing
├── payment_screen.dart       # Payment functionality
└── savings_screen.dart       # Savings management
```

Configuration

Firebase Collections Structure

Users Collection (`users`)
```json
{
  "name": "string",
  "email": "string", 
  "dob": "string",
  "profileImageUrl": "string",
  "createdAt": "timestamp"
}
```

Transactions Collection (`transactions`)
```json
{
  "userId": "string",
  "type": "deposit|withdrawal",
  "amount": "number",
  "description": "string",
  "date": "timestamp"
}
```

Loans Collection (`loans`)
```json
{
  "userId": "string",
  "balance": "number",
  "type": "string",
  "status": "string"
}
```

Security Features

- **Firebase Authentication** - Secure user management
- **User Data Isolation** - Each user only sees their own data
- **Input Validation** - Form validation and error handling
- **Secure Data Storage** - All data encrypted in Firebase


Known Issues

- Google Sign-In requires proper SHA-1 configuration
- Image upload currently stores local paths (needs Firebase Storage integration)
- Some features show "Coming Soon" dialogs

Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request






---

Disclaimer: This is a demo banking application for educational purposes. Do not use with real financial data or in production without proper security audits.
