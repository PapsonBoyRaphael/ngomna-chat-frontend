import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Service centralisé pour la gestion des chemins de fichiers
class PathService {
  static PathService? _instance;

  // Chemins en cache
  Directory? _appDocumentsDir;
  Directory? _tempDir;
  Directory? _externalStorageDir;
  Directory? _appSupportDir;

  factory PathService() {
    return _instance ??= PathService._internal();
  }

  PathService._internal();

  // 📁 Dossiers principaux

  /// Dossier Documents de l'application (persistant)
  Future<Directory> get appDocumentsDirectory async {
    _appDocumentsDir ??= await getApplicationDocumentsDirectory();
    return _appDocumentsDir!;
  }

  /// Dossier temporaire (peut être nettoyé par le système)
  Future<Directory> get temporaryDirectory async {
    _tempDir ??= await getTemporaryDirectory();
    return _tempDir!;
  }

  /// Stockage externe (Android) / Documents (iOS)
  Future<Directory?> get externalStorageDirectory async {
    if (_externalStorageDir == null) {
      try {
        _externalStorageDir = await getExternalStorageDirectory();
      } catch (e) {
        print('⚠️ External storage non disponible: $e');
        return null;
      }
    }
    return _externalStorageDir;
  }

  /// Dossier Support (iOS/macOS) - équivalent à Documents
  Future<Directory> get applicationSupportDirectory async {
    _appSupportDir ??= await getApplicationSupportDirectory();
    return _appSupportDir!;
  }

  // 📂 Dossiers spécialisés de l'application

  /// Dossier pour les photos de profil
  Future<Directory> get profileImagesDirectory async {
    final dir =
        Directory(p.join((await appDocumentsDirectory).path, 'Profile_images'));

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Dossier pour les fichiers de chat (documents, images, etc.)
  Future<Directory> get chatFilesDirectory async {
    final dir =
        Directory(p.join((await appDocumentsDirectory).path, 'chat_files'));

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Sous-dossier pour les images de chat
  Future<Directory> get chatImagesDirectory async {
    final dir = Directory(p.join((await chatFilesDirectory).path, 'Images'));

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Sous-dossier pour les documents
  Future<Directory> get chatDocumentsDirectory async {
    final dir = Directory(p.join((await chatFilesDirectory).path, 'Documents'));

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Sous-dossier pour les audios
  Future<Directory> get chatAudioDirectory async {
    final dir = Directory(p.join((await chatFilesDirectory).path, 'Audios'));

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Sous-dossier pour les vidéos
  Future<Directory> get chatVideosDirectory async {
    final dir = Directory(p.join((await chatFilesDirectory).path, 'Videos'));

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Cache réseau (images téléchargées)
  Future<Directory> get networkCacheDirectory async {
    final dir =
        Directory(p.join((await temporaryDirectory).path, 'Network_cache'));

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Cache avatars
  Future<Directory> get avatarCacheDirectory async {
    final dir =
        Directory(p.join((await networkCacheDirectory).path, 'Avatars'));

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Dossier Hive (base de données)
  Future<Directory> get hiveDirectory async {
    final dir =
        Directory(p.join((await appDocumentsDirectory).path, 'Hive_data'));

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Dossier logs
  Future<Directory> get logsDirectory async {
    final dir = Directory(p.join((await appDocumentsDirectory).path, 'Logs'));

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Dossier backup
  Future<Directory> get backupDirectory async {
    final externalDir = await externalStorageDirectory;
    if (externalDir != null) {
      final dir = Directory(p.join(externalDir.path, 'NGOMNA_Chat', 'Backups'));

      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }

    // Fallback sur app documents
    final dir =
        Directory(p.join((await appDocumentsDirectory).path, 'Backups'));

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // 🛠️ Méthodes utilitaires

  /// Générer un nom de fichier unique avec timestamp
  String generateUniqueFileName(String originalName, [String? prefix]) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = p.extension(originalName);
    final nameWithoutExt = p.basenameWithoutExtension(originalName);

    if (prefix != null) {
      return '${prefix}_${timestamp}_$nameWithoutExt$extension';
    }
    return '${timestamp}_$nameWithoutExt$extension';
  }

  /// Obtenir le chemin pour une image de profil
  Future<String> getProfileImagePath(String userId) async {
    final dir = await profileImagesDirectory;
    return p.join(dir.path, 'profile_$userId.jpg');
  }

  /// Obtenir le chemin pour un fichier de chat
  Future<String> getChatFilePath(String fileName, String fileType) async {
    Directory dir;

    switch (fileType.toLowerCase()) {
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        dir = await chatImagesDirectory;
        break;
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'xls':
      case 'xlsx':
      case 'txt':
        dir = await chatDocumentsDirectory;
        break;
      case 'mp3':
      case 'wav':
      case 'm4a':
        dir = await chatAudioDirectory;
        break;
      case 'mp4':
      case 'mov':
      case 'avi':
        dir = await chatVideosDirectory;
        break;
      default:
        dir = await chatFilesDirectory;
    }

    return p.join(dir.path, fileName);
  }

  /// Obtenir le chemin pour un avatar en cache
  Future<String> getCachedAvatarPath(String userId) async {
    final dir = await avatarCacheDirectory;
    return p.join(dir.path, 'avatar_$userId.jpg');
  }

  /// Obtenir le chemin Hive pour une box
  Future<String> getHiveBoxPath(String boxName) async {
    final dir = await hiveDirectory;
    return p.join(dir.path, '$boxName.hive');
  }

  /// Vérifier si un fichier existe
  Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }

  /// Obtenir la taille d'un fichier
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.size;
      }
      return 0;
    } catch (e) {
      print('❌ Erreur taille fichier $filePath: $e');
      return 0;
    }
  }

  /// Obtenir la taille totale d'un dossier
  Future<int> getDirectorySize(Directory directory) async {
    try {
      if (!await directory.exists()) return 0;

      int totalSize = 0;
      final files = directory.listSync(recursive: true);

      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }

      return totalSize;
    } catch (e) {
      print('❌ Erreur taille dossier ${directory.path}: $e');
      return 0;
    }
  }

  /// Nettoyer le cache (fichiers plus vieux que X jours)
  Future<void> cleanCache({int daysOld = 7}) async {
    try {
      final cacheDir = await networkCacheDirectory;
      if (!await cacheDir.exists()) return;

      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final files = cacheDir.listSync(recursive: true);

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
          }
        }
      }

      print('🧹 Cache nettoyé (fichiers > $daysOld jours)');
    } catch (e) {
      print('❌ Erreur nettoyage cache: $e');
    }
  }

  /// Obtenir les statistiques de stockage
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final appDir = await appDocumentsDirectory;
      final tempDir = await temporaryDirectory;
      final chatFilesDir = await chatFilesDirectory;
      final cacheDir = await networkCacheDirectory;
      final hiveDir = await hiveDirectory;

      return {
        'appDocumentsSize': await getDirectorySize(appDir),
        'tempSize': await getDirectorySize(tempDir),
        'chatFilesSize': await getDirectorySize(chatFilesDir),
        'cacheSize': await getDirectorySize(cacheDir),
        'hiveSize': await getDirectorySize(hiveDir),
        'appDocumentsPath': appDir.path,
        'tempPath': tempDir.path,
      };
    } catch (e) {
      print('❌ Erreur stats stockage: $e');
      return {};
    }
  }

  /// Créer un backup des données importantes
  Future<void> createBackup() async {
    try {
      final backupDir = await backupDirectory;
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupSubDir =
          Directory(p.join(backupDir.path, 'backup_$timestamp'));

      if (!await backupSubDir.exists()) {
        await backupSubDir.create(recursive: true);
      }

      // Copier les données Hive
      final hiveDir = await hiveDirectory;
      if (await hiveDir.exists()) {
        final hiveBackupDir = Directory(p.join(backupSubDir.path, 'hive'));
        await hiveBackupDir.create(recursive: true);

        final hiveFiles = hiveDir.listSync();
        for (final file in hiveFiles) {
          if (file is File) {
            final dest =
                File(p.join(hiveBackupDir.path, p.basename(file.path)));
            await file.copy(dest.path);
          }
        }
      }

      // Copier les fichiers de chat importants
      final chatFilesDir = await chatFilesDirectory;
      if (await chatFilesDir.exists()) {
        final chatBackupDir =
            Directory(p.join(backupSubDir.path, 'chat_files'));
        await chatBackupDir.create(recursive: true);

        await _copyDirectory(chatFilesDir, chatBackupDir);
      }

      print('✅ Backup créé: ${backupSubDir.path}');
    } catch (e) {
      print('❌ Erreur création backup: $e');
    }
  }

  /// Copier récursivement un dossier
  Future<void> _copyDirectory(Directory source, Directory destination) async {
    if (!await source.exists()) return;

    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }

    final files = source.listSync();

    for (final file in files) {
      final newPath = p.join(destination.path, p.basename(file.path));

      if (file is File) {
        await file.copy(newPath);
      } else if (file is Directory) {
        await _copyDirectory(file, Directory(newPath));
      }
    }
  }

  /// Dispose resources
  void dispose() {
    // Nettoyer le cache des chemins
    _appDocumentsDir = null;
    _tempDir = null;
    _externalStorageDir = null;
    _appSupportDir = null;
    _instance = null; // Permettre la recréation si nécessaire
    print('🧹 PathService nettoyé');
  }
}
