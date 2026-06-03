import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart'; // Memastikan route ke onboarding terhubung dengan benar

void main() {
  // PENTING: Memastikan binding framework Flutter siap karena OnboardingScreen
  // akan langsung mengeksekusi operasi asinkron (SharedPreferences & SQLite Init).
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PDWMartApp());
}

class PDWMartApp extends StatelessWidget {
  const PDWMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDW Mart',
      debugShowCheckedModeBanner:
          false, // Menghilangkan banner DEBUG agar tampilan profesional saat demo
      // Konfigurasi tema warna global mengikuti design system PDW Mart (Material 3)
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(
            0xFF00236F,
          ), // Deep Blue sebagai warna utama identitas toko
          primary: const Color(0xFF00236F),
          primaryContainer: const Color(0xFF1E3A8A),
          secondary: const Color(0xFF2170E4),
          surface: const Color(0xFFF7F9FB),
        ),
        // Menggunakan font Hanken Grotesk sesuai spesifikasi visual mockup
        fontFamily: 'Hanken Grotesk',
      ),

      // Gerbang utama aplikasi langsung diarahkan ke OnboardingScreen
      home: const OnboardingScreen(),
    );
  }
}
