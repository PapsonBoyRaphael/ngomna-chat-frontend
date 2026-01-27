import 'package:flutter/material.dart';
import 'core/routes/app_routes.dart';

void main() {
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
      ),
      initialRoute: AppRoutes.welcome,
      routes: AppRoutes.getRoutes(),
    );
  }
}
