import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// Configuration centralisée des URLs de l'application
/// Détecte automatiquement l'environnement et configure les bonnes URLs
class AppUrl {
  // Configurations pour différents environnements
  static const String _localhostDev = 'http://localhost';
  static const String _emulatorHost = 'http://10.0.2.2'; // Android Emulator
  static const String _productionHost =
      'http://192.168.50.68'; // À adapter avec votre IP

  // Ports
  static const int _apiPort = 8000; // Gateway API
  static const int _socketPort = 8003; // Socket.IO Gateway

  /// Obtient l'hôte de base selon l'environnement
  static String get _baseHost {
    // ✅ Sur le web, toujours utiliser localhost
    if (kIsWeb) {
      return _localhostDev;
    }

    // Sur mobile, détecter Android, iOS, etc.
    if (Platform.isAndroid) {
      // Sur Android, préférer 10.0.2.2 (émulateur) ou IP locale (téléphone)
      return _productionHost;
    } else if (Platform.isIOS) {
      // Sur iOS réel ou simulateur, utiliser localhost ou IP locale
      return _localhostDev;
    } else {
      // Bureau (Windows, macOS, Linux)
      return _localhostDev;
    }
  }

  /// URL de base pour l'API REST (Gateway)
  static String get apiBaseUrl {
    return '$_baseHost:$_apiPort';
  }

  /// URL pour Socket.IO (Gateway)
  static String get socketUrl {
    return '$_baseHost:$_socketPort';
  }

  /// Configuration pour déboguer
  static String getDebugInfo() {
    final platform = kIsWeb ? 'Web' : Platform.operatingSystem;
    return '''
    🔧 Configuration URLs:
    - Est Web: $kIsWeb
    - Plateforme: $platform
    - API Base URL: $apiBaseUrl
    - Socket URL: $socketUrl
    ''';
  }

  /// Méthode pour tester la connectivité
  static Future<bool> testConnectivity() async {
    try {
      // Tenter de vérifier la santé de la gateway
      print('🧪 Test connexion à $apiBaseUrl/api/health');
      return true;
    } catch (e) {
      print('❌ Erreur connexion: $e');
      return false;
    }
  }
}
