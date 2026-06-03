import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart'; // route ke onboarding

void main() {
  // inisialisasi binding flutter biar ga error pas manggil async
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PDWMartApp());
}

class PDWMartApp extends StatelessWidget {
  const PDWMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDW Mart',
      debugShowCheckedModeBanner: false, // matiin banner debug
      // setting tema aplikasi
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00236F), // warna utama deep blue
          primary: const Color(0xFF00236F),
          primaryContainer: const Color(0xFF1E3A8A),
          secondary: const Color(0xFF2170E4),
          surface: const Color(0xFFF7F9FB),
        ),
        fontFamily: 'Hanken Grotesk', // pake font hanken grotesk
      ),
      home: const OnboardingScreen(), // arahin ke onboarding pas pertama buka
    );
  }
}
