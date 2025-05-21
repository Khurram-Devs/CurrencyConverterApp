  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:flutter/material.dart';
  import '../widgets/login_signup_widget.dart';

  class SettingsScreen extends StatelessWidget {
    const SettingsScreen({super.key});

    @override
    Widget build(BuildContext context) {
      final user = FirebaseAuth.instance.currentUser;
      return user == null
          ? const LoginSignupWidget()
          : const Text("Logged in"); // your logged-in UI
    }
  }
