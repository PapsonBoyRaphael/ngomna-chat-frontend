import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ngomna_chat/providers/app_providers.dart';
import 'package:ngomna_chat/core/routes/app_routes.dart';
import 'package:ngomna_chat/core/constants/app_fonts.dart';
import 'package:ngomna_chat/data/models/chat_model.dart';
import 'package:ngomna_chat/data/models/message_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialiser Hive
  await Hive.initFlutter();

  // Enregistrer les adapters Hive
  Hive.registerAdapter(ChatAdapter());
  Hive.registerAdapter(ChatTypeAdapter()); // Adapter pour l'enum ChatType
  Hive.registerAdapter(ParticipantMetadataAdapter());
  Hive.registerAdapter(NotificationSettingsAdapter());
  Hive.registerAdapter(LastMessageAdapter());
  Hive.registerAdapter(ChatSettingsAdapter());
  Hive.registerAdapter(ChatMetadataAdapter());
  Hive.registerAdapter(AuditLogEntryAdapter());
  Hive.registerAdapter(ChatStatsAdapter());
  Hive.registerAdapter(ChatIntegrationsAdapter());
  Hive.registerAdapter(MessageAdapter());
  Hive.registerAdapter(MessageTypeAdapter()); // Adapter pour l'enum MessageType
  Hive.registerAdapter(
      MessageStatusAdapter()); // Adapter pour l'enum MessageStatus
  Hive.registerAdapter(
      MessagePriorityAdapter()); // Adapter pour l'enum MessagePriority
  Hive.registerAdapter(MessageMetadataAdapter());
  Hive.registerAdapter(TechnicalMetadataAdapter());
  Hive.registerAdapter(KafkaMetadataAdapter());
  Hive.registerAdapter(RedisMetadataAdapter());
  Hive.registerAdapter(DeliveryMetadataAdapter());
  Hive.registerAdapter(ContentMetadataAdapter());

  // 🔥 Initialiser les services via AppProviders
  await AppProviders.initializeServices();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders.wrapWithProviders(
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
