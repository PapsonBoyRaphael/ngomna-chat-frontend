import 'package:flutter/material.dart';

class AppFonts {
  // 🎨 FAMILLES DE POLICES ROBOTO (chaque variante est une famille)
  static const String robotoRegular = 'Roboto-Regular';
  static const String robotoMedium = 'Roboto-Medium';
  static const String robotoSemiBold = 'Roboto-SemiBold';
  static const String robotoBold = 'Roboto-Bold';
  static const String robotoExtraBold = 'Roboto-ExtraBold';

  // 🎨 FAMILLES DE POLICES ROSARIO
  static const String rosarioRegular = 'Rosario-Regular';
  static const String rosarioMedium = 'Rosario-Medium';

  // 📝 STYLES PRÉDÉFINIS POUR LES TITRES
  static const TextStyle heading1 = TextStyle(
    fontFamily: rosarioMedium,
    fontSize: 28,
    height: 1.6,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: rosarioMedium,
    fontSize: 24,
    height: 1.6,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: robotoSemiBold,
    fontSize: 20,
  );

  // 📝 STYLES POUR LE CORPS DE TEXTE
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: robotoRegular,
    fontSize: 17,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: robotoRegular,
    fontSize: 15,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: robotoRegular,
    fontSize: 13,
  );

  // 📝 STYLES POUR LES BOUTONS
  static const TextStyle buttonText = TextStyle(
    fontFamily: robotoExtraBold,
    fontSize: 18,
    letterSpacing: 1.2,
  );

  static const TextStyle buttonTextMedium = TextStyle(
    fontFamily: robotoSemiBold,
    fontSize: 16,
  );

  // 📝 STYLES POUR LES LABELS
  static const TextStyle label = TextStyle(
    fontFamily: robotoMedium,
    fontSize: 14,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: robotoRegular,
    fontSize: 12,
  );

  // 📝 STYLES POUR LES MESSAGES
  static const TextStyle messageText = TextStyle(
    fontFamily: robotoRegular,
    fontSize: 15,
    height: 1.35,
  );

  static const TextStyle messageTime = TextStyle(
    fontFamily: robotoRegular,
    fontSize: 12,
  );

  // 📝 STYLES POUR LES CHATS
  static const TextStyle chatName = TextStyle(
    fontFamily: robotoSemiBold,
    fontSize: 17,
  );

  static const TextStyle chatNameGroup = TextStyle(
    fontFamily: robotoExtraBold,
    fontSize: 17,
  );

  static const TextStyle chatLastMessage = TextStyle(
    fontFamily: robotoRegular,
    fontSize: 16,
  );
}
