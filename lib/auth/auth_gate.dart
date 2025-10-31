import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service_web.dart';
import '../screens/home_screen.dart';
import '../screens/landing_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authWeb
          .authState(), // or FirebaseAuth.instance.authStateChanges()
      builder: (context, snap) {
        // Splash/loading
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Signed in → app
        if (snap.data != null) {
          return const HomeScreen();
        }
        return const LandingPage();
      },
    );
  }
}
