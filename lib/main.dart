import 'package:flutter/material.dart';
import 'core/routes/app_routes.dart';
import 'core/constants/app_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NGOMNA Chat',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF4FFFB),
        fontFamily: AppFonts.robotoRegular,
        primaryColor: const Color(0xFF4CAF50),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
        ),
      ),
      initialRoute: AppRoutes.welcome,
      routes: AppRoutes.getRoutes(),
    );
  }
}
