import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth_screen.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://jcuiazejigywckemuejz.supabase.co',
    anonKey: 'sb_publishable_sfFMriTDBFRMhXzxT8ugZQ_pBXjBKrg',
  );
  runApp(MyApp());
}
final supabase = Supabase.instance.client;
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyClear Community',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const AuthScreen(),
    );
  }
}
