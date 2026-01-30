import 'package:intl/intl.dart';

/// Utilitaire pour formater les dates selon les règles d'affichage
class DateFormatter {
  static const List<String> _dayNames = [
    'Dimanche',
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi'
  ];
  static const List<String> _dayNamesShort = [
    'Dim',
    'Lun',
    'Mar',
    'Mer',
    'Jeu',
    'Ven',
    'Sam'
  ];

  /// Formate une date pour les tuiles de conversation :
  /// - Moins de 24h : heure (ex: "14:30")
  /// - Hier : "Hier"
  /// - Cette semaine : jour abrégé (ex: "Lun")
  /// - Plus ancien : date (ex: "12/01/2026")
  static String formatMessageDate(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final difference = now.difference(date);

    // Si la date est très récente (< 1 seconde), c'est probablement une date invalide
    if (difference.inSeconds < 1) {
      print(
          '⚠️ DateFormatter.formatMessageDate - date invalide détectée: différence = ${difference.inSeconds}s');
      return '';
    }

    // Moins de 24 heures : afficher l'heure
    if (difference.inHours < 24) {
      return DateFormat('HH:mm').format(date);
    }

    // Hier
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Hier';
    }

    // Cette semaine (du lundi au dimanche)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    if (date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)))) {
      return _dayNamesShort[date.weekday % 7];
    }

    // Plus ancien : date complète
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Formate une date pour les séparateurs dans les conversations :
  /// - Aujourd'hui : "Aujourd'hui"
  /// - Hier : "Hier"
  /// - Cette semaine : jour complet (ex: "Lundi")
  /// - Plus ancien : date (ex: "12 janv. 2026")
  static String formatDateSeparator(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final difference = now.difference(date);

    // Si la date est très récente (< 1 seconde), c'est probablement une date invalide
    if (difference.inSeconds < 1) {
      print(
          '⚠️ DateFormatter.formatDateSeparator - date invalide détectée: différence = ${difference.inSeconds}s');
      return '';
    }

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Aujourd\'hui';
    } else if (messageDate == yesterday) {
      return 'Hier';
    }

    // Cette semaine (du lundi au dimanche)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    if (date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)))) {
      return _dayNames[date.weekday % 7];
    }

    // Plus ancien : date avec mois abrégé
    return DateFormat('d MMM yyyy', 'fr_FR').format(date);
  }

  /// Version alternative pour les dates relatives (utile pour debug)
  static String formatRelativeDate(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final difference = now.difference(date);

    // Si la date est très récente (< 1 seconde), c'est probablement une date invalide
    if (difference.inSeconds < 1) {
      print(
          '⚠️ DateFormatter.formatRelativeDate - date invalide détectée: différence = ${difference.inSeconds}s');
      return '';
    }

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}
