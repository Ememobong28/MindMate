import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_web_options.dart';
import 'auth/auth_gate.dart';
import 'services/history.dart';
import 'services/commitments_store.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/landing_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseWebOptions);

  await HistoryStore.instance.start();
  // await CommitmentsStore.instance.start();

  runApp(const MindMateApp());
}

class MindMateApp extends StatelessWidget {
  const MindMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        fontFamilyFallback: const [
          'Noto Color Emoji',
          'Apple Color Emoji',
          'Segoe UI Emoji',
        ],
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4F46E5),
        brightness: Brightness.light,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ),

      // AuthGate decides Landing vs Home
      initialRoute: '/',
      routes: {
        '/': (ctx) => const AuthGate(),
        '/login': (ctx) => const LoginScreen(),
        '/signup': (ctx) => const SignUpScreen(),
        '/landing': (ctx) => const LandingPage(),
      },
      // Optional deep link to sign-up
      onGenerateRoute: (settings) {
        if (settings.name == '/get-started') {
          return MaterialPageRoute(builder: (_) => const SignUpScreen());
        }
        return null;
      },
    );
  }
}
