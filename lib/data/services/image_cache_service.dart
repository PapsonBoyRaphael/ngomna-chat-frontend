import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:ngomna_chat/data/services/path_service.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart' as crypto;
import 'dart:convert';

/// Service de cache d'images avec hash d'URL
class ImageCacheService {
  final PathService _pathService = PathService();
  final Dio _dio = Dio();

  // Cache mémoire pour éviter les lectures disque répétées
  final Map<String, String> _memoryCache = {};

  /// Obtenir une image depuis URL avec cache
  Future<File?> getImage(String imageUrl, {bool forceRefresh = false}) async {
    try {
      // Générer un hash de l'URL pour le nom de fichier
      final fileName = _generateFileNameFromUrl(imageUrl);
      final cachePath = await _pathService.getCachedAvatarPath(fileName);

      // Vérifier en cache mémoire d'abord
      if (_memoryCache.containsKey(imageUrl) && !forceRefresh) {
        final cachedPath = _memoryCache[imageUrl]!;
        final file = File(cachedPath);
        if (await file.exists()) {
          return file;
        }
      }

      // Vérifier en cache disque
      final cachedFile = File(cachePath);
      if (await cachedFile.exists() && !forceRefresh) {
        _memoryCache[imageUrl] = cachePath;
        return cachedFile;
      }

      // Télécharger depuis le réseau
      final downloadedFile = await _downloadAndCacheImage(imageUrl, cachePath);
      if (downloadedFile != null) {
        _memoryCache[imageUrl] = cachePath;
      }

      return downloadedFile;
    } catch (e) {
      print('❌ Erreur cache image $imageUrl: $e');
      return null;
    }
  }

  /// Télécharger et mettre en cache
  Future<File?> _downloadAndCacheImage(String url, String cachePath) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        final bytes = response.data as List<int>;
        final file = File(cachePath);

        // Créer le dossier parent si nécessaire
        await file.parent.create(recursive: true);

        await file.writeAsBytes(bytes);
        print('✅ Image téléchargée et mise en cache: ${p.basename(cachePath)}');
        return file;
      }
    } catch (e) {
      print('❌ Erreur téléchargement image: $e');
    }
    return null;
  }

  /// Générer un nom de fichier unique à partir d'une URL
  String _generateFileNameFromUrl(String url) {
    final bytes = utf8.encode(url);
    final digest = crypto.md5.convert(bytes);
    return digest.toString();
  }

  /// Préchauffer le cache (télécharger en arrière-plan)
  Future<void> preCacheImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      try {
        await getImage(url);
      } catch (e) {
        // Ignorer les erreurs en pré-cache
      }
    }
  }

  /// Nettoyer les images non utilisées
  Future<void> cleanUnusedImages(Set<String> usedImageUrls) async {
    try {
      final cacheDir = await _pathService.avatarCacheDirectory;
      if (!await cacheDir.exists()) return;

      final files = cacheDir.listSync();
      final usedFileNames = usedImageUrls.map(_generateFileNameFromUrl).toSet();

      for (final file in files) {
        if (file is File) {
          final fileName = p.basenameWithoutExtension(file.path);
          if (!usedFileNames.contains(fileName.replaceFirst('avatar_', ''))) {
            // Fichier non utilisé depuis plus d'un mois
            final stat = await file.stat();
            if (stat.modified
                .isBefore(DateTime.now().subtract(Duration(days: 30)))) {
              await file.delete();
              print('🗑️ Image nettoyée: ${file.path}');
            }
          }
        }
      }
    } catch (e) {
      print('❌ Erreur nettoyage images: $e');
    }
  }

  /// Obtenir les statistiques du cache
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final cacheDir = await _pathService.avatarCacheDirectory;
      if (!await cacheDir.exists()) {
        return {'fileCount': 0, 'totalSize': 0};
      }

      int fileCount = 0;
      int totalSize = 0;

      final files = cacheDir.listSync();
      for (final file in files) {
        if (file is File) {
          fileCount++;
          totalSize += await file.length();
        }
      }

      return {
        'fileCount': fileCount,
        'totalSize': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        'cachePath': cacheDir.path,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
