import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ngomna_chat/core/routes/app_routes.dart';
import 'package:ngomna_chat/core/constants/app_fonts.dart';
import 'package:ngomna_chat/data/services/api_service.dart';
import 'package:ngomna_chat/data/services/storage_service.dart';
import 'package:ngomna_chat/data/services/socket_service.dart';
import 'package:ngomna_chat/data/repositories/auth_repository.dart';
import 'package:ngomna_chat/data/repositories/message_repository.dart';
import 'package:ngomna_chat/viewmodels/auth_viewmodel.dart';
import 'package:ngomna_chat/viewmodels/message_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 🔧 Services (singletons)
        Provider<ApiService>(
          create: (_) => ApiService(),
          dispose: (_, service) {}, // Dio n'a pas besoin de dispose
        ),
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),

        // 🌐 SocketService (singleton avec dispose important)
        Provider<SocketService>(
          create: (_) => SocketService(),
          dispose: (_, service) => service.dispose(),
        ),

        // 📦 Repositories
        Provider<AuthRepository>(
          create: (context) => AuthRepository(
            apiService: context.read<ApiService>(),
            storageService: context.read<StorageService>(),
          ),
        ),

        Provider<MessageRepository>(
          create: (context) => MessageRepository(
            socketService: context.read<SocketService>(),
            apiService: context.read<ApiService>(),
          ),
          dispose: (_, repo) => repo.dispose(),
        ),

        // 🧠 ViewModels (ChangeNotifier)
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            context.read<AuthRepository>(),
          ),
          lazy: false, // Initialiser tout de suite pour vérifier l'auth
        ),

        ChangeNotifierProvider<MessageViewModel>(
          create: (context) => MessageViewModel(
            context.read<MessageRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
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
      ),
    );
  }
}
