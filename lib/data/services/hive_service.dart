import 'package:hive_flutter/hive_flutter.dart';
import 'package:ngomna_chat/data/models/message_model.dart';
import 'package:ngomna_chat/data/models/chat_model.dart';

class HiveService {
  static const String _messagesBox = 'messages';
  static const String _chatsBox = 'chats';
  static const String _settingsBox = 'app_settings';
  static const String _userDataBox = 'user_data';

  // 🔥 Messages

  /// Sauvegarder un message
  Future<void> saveMessage(Message message) async {
    try {
      final box = await Hive.openBox<Message>(_messagesBox);
      await box.put(message.id, message);
      print('💾 Message sauvegardé: ${message.id}');
    } catch (e) {
      print('❌ Erreur sauvegarde message: $e');
    }
  }

  /// Sauvegarder plusieurs messages
  Future<void> saveMessages(List<Message> messages) async {
    try {
      final box = await Hive.openBox<Message>(_messagesBox);
      final Map<String, Message> messageMap = {
        for (var msg in messages) msg.id: msg
      };
      await box.putAll(messageMap);
      print('💾 ${messages.length} messages sauvegardés');
    } catch (e) {
      print('❌ Erreur sauvegarde messages batch: $e');
    }
  }

  /// Récupérer les messages d'une conversation
  Future<List<Message>> getMessagesForConversation(
    String conversationId, {
    int? limit,
    int? offset,
  }) async {
    try {
      final box = await Hive.openBox<Message>(_messagesBox);
      var messages = box.values
          .where((msg) => msg.conversationId == conversationId)
          .toList();

      // Trier par timestamp (plus récent en dernier)
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Appliquer pagination si spécifiée
      if (offset != null && offset > 0) {
        messages = messages.skip(offset).toList();
      }
      if (limit != null && limit > 0) {
        messages = messages.take(limit).toList();
      }

      print(
          '📥 ${messages.length} messages récupérés pour $conversationId (limit: $limit, offset: $offset)');
      return messages;
    } catch (e) {
      print('❌ Erreur récupération messages: $e');
      return [];
    }
  }

  /// Récupérer le dernier message d'une conversation
  Future<Message?> getLastMessageForConversation(String conversationId) async {
    try {
      final messages = await getMessagesForConversation(conversationId);
      return messages.isNotEmpty ? messages.last : null;
    } catch (e) {
      print('❌ Erreur dernier message: $e');
      return null;
    }
  }

  /// Récupérer un message par ID
  Future<Message?> getMessageById(String messageId) async {
    try {
      final box = await Hive.openBox<Message>(_messagesBox);
      return box.get(messageId);
    } catch (e) {
      print('❌ Erreur récupération message: $e');
      return null;
    }
  }

  /// Supprimer les messages d'une conversation
  Future<void> deleteMessagesForConversation(String conversationId) async {
    try {
      final box = await Hive.openBox<Message>(_messagesBox);
      final messagesToDelete = box.values
          .where((msg) => msg.conversationId == conversationId)
          .map((msg) => msg.id)
          .toList();

      await box.deleteAll(messagesToDelete);
      print(
          '🗑️ ${messagesToDelete.length} messages supprimés pour $conversationId');
    } catch (e) {
      print('❌ Erreur suppression messages: $e');
    }
  }

  // 🔥 Chats (Conversations)

  /// Sauvegarder une conversation
  Future<void> saveChat(Chat chat) async {
    try {
      final box = await Hive.openBox<Chat>(_chatsBox);
      await box.put(chat.id, chat);
      print('💾 Conversation sauvegardée: ${chat.name}');
    } catch (e) {
      print('❌ Erreur sauvegarde conversation: $e');
    }
  }

  /// Sauvegarder plusieurs conversations
  Future<void> saveChats(List<Chat> chats) async {
    try {
      final box = await Hive.openBox<Chat>(_chatsBox);
      final Map<String, Chat> chatMap = {for (var chat in chats) chat.id: chat};
      await box.putAll(chatMap);
      print('💾 ${chats.length} conversations sauvegardées');
    } catch (e) {
      print('❌ Erreur sauvegarde conversations batch: $e');
    }
  }

  /// Récupérer toutes les conversations
  Future<List<Chat>> getAllChats() async {
    try {
      final box = await Hive.openBox<Chat>(_chatsBox);
      final chats = box.values.toList();

      // Trier par dernier message (plus récent en premier)
      chats.sort((a, b) {
        final aTime = a.lastMessageTime ?? DateTime(1970);
        final bTime = b.lastMessageTime ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      print('📥 ${chats.length} conversations récupérées');
      return chats;
    } catch (e) {
      print('❌ Erreur récupération conversations: $e');
      return [];
    }
  }

  /// Récupérer une conversation spécifique
  Future<Chat?> getChat(String chatId) async {
    try {
      final box = await Hive.openBox<Chat>(_chatsBox);
      return box.get(chatId);
    } catch (e) {
      print('❌ Erreur récupération conversation: $e');
      return null;
    }
  }

  /// Mettre à jour le dernier message d'une conversation
  Future<void> updateChatLastMessage(String chatId, String lastMessage,
      DateTime timestamp, String senderId) async {
    try {
      final chat = await getChat(chatId);
      if (chat != null) {
        final newLastMessage = LastMessage(
          content: lastMessage,
          senderId: senderId,
          timestamp: timestamp,
          type: 'TEXT',
        );
        final updatedChat = chat.copyWith(
          lastMessage: newLastMessage,
          lastMessageAt: timestamp,
        );
        await saveChat(updatedChat);
        print('🔄 Dernier message mis à jour pour: ${chat.name}');
      }
    } catch (e) {
      print('❌ Erreur mise à jour dernier message: $e');
    }
  }

  // 🔥 Settings

  /// Sauvegarder un paramètre
  Future<void> saveSetting(String key, dynamic value) async {
    try {
      final box = await Hive.openBox(_settingsBox);
      await box.put(key, value);
    } catch (e) {
      print('❌ Erreur sauvegarde setting: $e');
    }
  }

  /// Récupérer un paramètre
  Future<dynamic> getSetting(String key, {dynamic defaultValue}) async {
    try {
      final box = await Hive.openBox(_settingsBox);
      return box.get(key, defaultValue: defaultValue);
    } catch (e) {
      print('❌ Erreur récupération setting: $e');
      return defaultValue;
    }
  }

  // 🔥 User Data

  /// Sauvegarder des données utilisateur
  Future<void> saveUserData(String key, dynamic value) async {
    try {
      final box = await Hive.openBox(_userDataBox);
      await box.put(key, value);
    } catch (e) {
      print('❌ Erreur sauvegarde user data: $e');
    }
  }

  /// Récupérer des données utilisateur
  Future<dynamic> getUserData(String key, {dynamic defaultValue}) async {
    try {
      final box = await Hive.openBox(_userDataBox);
      return box.get(key, defaultValue: defaultValue);
    } catch (e) {
      print('❌ Erreur récupération user data: $e');
      return defaultValue;
    }
  }

  // 🔥 Utilitaires

  /// Vider toutes les données (debug/déconnexion)
  Future<void> clearAllData() async {
    try {
      await Hive.box(_messagesBox).clear();
      await Hive.box(_chatsBox).clear();
      await Hive.box(_settingsBox).clear();
      await Hive.box(_userDataBox).clear();
      print('🧹 Toutes les données Hive effacées');
    } catch (e) {
      print('❌ Erreur effacement données: $e');
    }
  }

  /// Obtenir des statistiques
  Future<Map<String, int>> getStats() async {
    try {
      final messagesBox = await Hive.openBox<Message>(_messagesBox);
      final chatsBox = await Hive.openBox<Chat>(_chatsBox);

      return {
        'messages': messagesBox.length,
        'chats': chatsBox.length,
      };
    } catch (e) {
      return {'messages': 0, 'chats': 0};
    }
  }

  /// Dispose resources
  void dispose() {
    // Hive gère automatiquement la fermeture des boxes
    // mais on peut forcer la fermeture si nécessaire
    print('🧹 HiveService nettoyé');
  }
}
