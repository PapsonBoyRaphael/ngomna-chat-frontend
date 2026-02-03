import 'package:flutter/material.dart';
import 'package:ngomna_chat/providers/app_providers.dart';
import 'package:ngomna_chat/core/routes/app_routes.dart';
import 'package:ngomna_chat/core/constants/app_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  // 🔥 Initialiser Flutter
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('fr_FR', null);

  // Configurer le builder d'erreur global
  ErrorWidget.builder = (FlutterErrorDetails details) {
    print('💥 Erreur Flutter globale: ${details.exception}');
    print('Stack trace: ${details.stack}');
    return const ErrorScreen(
      title: 'Erreur Application',
      message: 'Une erreur inattendue s\'est produite.',
    );
  };

  // 🔥 Initialiser tous les services (Hive + Services) avec gestion d'erreur
  try {
    await AppProviders.initializeServices();
    print('🚀 Application démarrée avec succès');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('💥 Erreur critique lors de l\'initialisation: $e');
    print('Stack trace: $stackTrace');

    // En cas d'erreur critique, afficher un écran d'erreur
    runApp(const InitializationErrorApp(error: 'Erreur d\'initialisation'));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders.wrapWithProviders(
      child: Builder(
        builder: (context) {
          // Initialiser les repositories après la construction des providers
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppProviders.initializeRepositories(context);
          });

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
            // Gestion des routes inconnues
            onUnknownRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const ErrorScreen(
                  title: 'Page introuvable',
                  message: 'La page demandée n\'existe pas.',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Écran d'erreur d'initialisation (affiché si l'app ne peut pas démarrer)
class InitializationErrorApp extends StatelessWidget {
  const InitializationErrorApp({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NGOMNA Chat - Erreur',
      home: ErrorScreen(
        title: 'Erreur de démarrage',
        message: 'Impossible de démarrer l\'application: $error',
        showRetryButton: true,
      ),
    );
  }
}

/// Écran d'erreur générique
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({
    super.key,
    required this.title,
    required this.message,
    this.showRetryButton = false,
  });

  static bool _hasRedirected = false;

  final String title;
  final String message;
  final bool showRetryButton;

  @override
  Widget build(BuildContext context) {
    if (title == 'Erreur Application' &&
        message == 'Une erreur inattendue s\'est produite.' &&
        !_hasRedirected) {
      _hasRedirected = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.enterMatricule);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4FFFB),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Color(0xFF4CAF50),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
              if (showRetryButton) ...[
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Redémarrer l'application
                    main();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'Réessayer',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
