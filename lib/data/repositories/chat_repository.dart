import 'package:ngomna_chat/data/models/chat_model.dart';
import 'package:ngomna_chat/data/models/message_model.dart';
import 'package:ngomna_chat/core/constants/app_assets.dart';

class ChatRepository {
  // Mock data (sera remplacé par API plus tard)
  Future<List<Chat>> getChats() async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();

    return [
      Chat(
        id: '1',
        name: 'Mrs. Aichatou Bello',
        type: ChatType.personal,
        participants: ['current_user_id_placeholder', 'user_1'],
        createdBy: 'current_user_id_placeholder',
        userMetadata: [
          ParticipantMetadata(
            userId: 'current_user_id_placeholder',
            unreadCount: 0,
            isMuted: false,
            isPinned: false,
            notificationSettings: NotificationSettings(
              enabled: true,
              sound: true,
              vibration: true,
            ),
            nom: 'User',
            prenom: 'You',
            avatar: AppAssets.avatar,
            metadataId: 'meta_current_user',
          ),
          ParticipantMetadata(
            userId: 'user_1',
            unreadCount: 0,
            isMuted: false,
            isPinned: false,
            notificationSettings: NotificationSettings(
              enabled: true,
              sound: true,
              vibration: true,
            ),
            nom: 'Bello',
            prenom: 'Mrs. Aichatou',
            avatar: AppAssets.avatar,
            metadataId: 'meta_user_1',
          ),
        ],
        unreadCounts: {'current_user_id_placeholder': 0, 'user_1': 0},
        lastMessageAt: now.subtract(const Duration(hours: 1)),
        settings: ChatSettings(
          allowInvites: true,
          isPublic: false,
          maxParticipants: 2,
          messageRetention: 30,
        ),
        metadata: ChatMetadata(
          stats: ChatStats(
            totalMessages: 10,
            totalParticipants: 2,
            lastActivity: now.subtract(const Duration(hours: 1)),
          ),
        ),
        integrations: ChatIntegrations(),
        createdAt: now,
        updatedAt: now,
        lastMessage: LastMessage(
          content: 'ok done ...',
          type: 'TEXT',
          senderId: 'user_1',
          senderName: 'Mrs. Aichatou Bello',
          timestamp: now.subtract(const Duration(hours: 1)),
          status: MessageStatus.sent,
        ),
      ),
      Chat(
        id: '2',
        name: 'NGOMNA PRESENTATION',
        type: ChatType.group,
        participants: ['current_user_id_placeholder', 'user_2', 'user_3'],
        createdBy: 'current_user_id_placeholder',
        userMetadata: [
          ParticipantMetadata(
            userId: 'current_user_id_placeholder',
            unreadCount: 0,
            isMuted: false,
            isPinned: false,
            notificationSettings: NotificationSettings(
              enabled: true,
              sound: true,
              vibration: true,
            ),
            nom: 'User',
            prenom: 'You',
            avatar: AppAssets.avatar,
            metadataId: 'meta_current_user_2',
          ),
          ParticipantMetadata(
            userId: 'user_2',
            unreadCount: 0,
            isMuted: false,
            isPinned: false,
            notificationSettings: NotificationSettings(
              enabled: true,
              sound: true,
              vibration: true,
            ),
            nom: 'Bello',
            prenom: 'Mrs. Aichatou',
            avatar: AppAssets.avatar,
            metadataId: 'meta_user_2',
          ),
          ParticipantMetadata(
            userId: 'user_3',
            unreadCount: 0,
            isMuted: false,
            isPinned: false,
            notificationSettings: NotificationSettings(
              enabled: true,
              sound: true,
              vibration: true,
            ),
            nom: 'Owona',
            prenom: 'Mr. Ngah',
            avatar: AppAssets.avatar,
            metadataId: 'meta_user_3',
          ),
        ],
        unreadCounts: {
          'current_user_id_placeholder': 0,
          'user_2': 0,
          'user_3': 0
        },
        lastMessageAt: now.subtract(const Duration(hours: 2)),
        settings: ChatSettings(
          allowInvites: true,
          isPublic: true,
          maxParticipants: 50,
          messageRetention: 30,
        ),
        metadata: ChatMetadata(
          stats: ChatStats(
            totalMessages: 25,
            totalParticipants: 3,
            lastActivity: now.subtract(const Duration(hours: 2)),
          ),
        ),
        integrations: ChatIntegrations(),
        createdAt: now,
        updatedAt: now,
        lastMessage: LastMessage(
          content: 'Mrs. Aichatou Bello',
          type: 'TEXT',
          senderId: 'user_2',
          senderName: 'Mrs. Aichatou Bello',
          timestamp: now.subtract(const Duration(hours: 2)),
          status: MessageStatus.sent,
        ),
      ),
      Chat(
        id: '3',
        name: 'Mrs. Sheina Tchuente',
        type: ChatType.personal,
        participants: ['current_user_id_placeholder', 'user_4'],
        createdBy: 'current_user_id_placeholder',
        userMetadata: [
          ParticipantMetadata(
            userId: 'current_user_id_placeholder',
            unreadCount: 0,
            isMuted: false,
            isPinned: false,
            notificationSettings: NotificationSettings(
              enabled: true,
              sound: true,
              vibration: true,
            ),
            nom: 'User',
            prenom: 'You',
            avatar: AppAssets.avatar,
            metadataId: 'meta_current_user_3',
          ),
          ParticipantMetadata(
            userId: 'user_4',
            unreadCount: 0,
            isMuted: false,
            isPinned: false,
            notificationSettings: NotificationSettings(
              enabled: true,
              sound: true,
              vibration: true,
            ),
            nom: 'Tchuente',
            prenom: 'Mrs. Sheina',
            avatar: AppAssets.avatar,
            metadataId: 'meta_user_4',
          ),
        ],
        unreadCounts: {'current_user_id_placeholder': 0, 'user_4': 0},
        lastMessageAt: now.subtract(const Duration(hours: 12)),
        settings: ChatSettings(
          allowInvites: true,
          isPublic: false,
          maxParticipants: 2,
          messageRetention: 30,
        ),
        metadata: ChatMetadata(
          stats: ChatStats(
            totalMessages: 8,
            totalParticipants: 2,
            lastActivity: now.subtract(const Duration(hours: 12)),
          ),
        ),
        integrations: ChatIntegrations(),
        createdAt: now,
        updatedAt: now,
        lastMessage: LastMessage(
          content: 'hahahahaha...',
          type: 'TEXT',
          senderId: 'user_4',
          senderName: 'Mrs. Sheina Tchuente',
          timestamp: now.subtract(const Duration(hours: 12)),
          status: MessageStatus.sent,
        ),
      ),
      Chat(
        id: '4',
        name: 'MINFI PROJECT',
        type: ChatType.group,
        participants: ['current_user_id_placeholder', 'user_5', 'user_6'],
        createdBy: 'current_user_id_placeholder',
        userMetadata: [
          ParticipantMetadata(
            userId: 'current_user_id_placeholder',
            unreadCount: 0,
            isMuted: false,
            isPinned: false,
            notificationSettings: NotificationSettings(
              enabled: true,
              sound: true,
              vibration: true,
            ),
            nom: 'User',
            prenom: 'You',
            avatar: AppAssets.avatar,
            metadataId: 'meta_current_user_4',
          ),
          ParticipantMetadata(
            userId: 'user_5',
            unreadCount: 0,
            isMuted: false,
            isPinned: false,
            notificationSettings: NotificationSettings(
              enabled: true,
              sound: true,
              vibration: true,
            ),
            nom: 'Telma',
            prenom: 'Mrs. Angu',
            avatar: AppAssets.avatar,
            metadataId: 'meta_user_5',
          ),
          ParticipantMetadata(
            userId: 'user_6',
            unreadCount: 0,
            isMuted: false,
            isPinned: false,
            notificationSettings: NotificationSettings(
              enabled: true,
              sound: true,
              vibration: true,
            ),
            nom: 'Owona',
            prenom: 'Mr. Ngah',
            avatar: AppAssets.avatar,
            metadataId: 'meta_user_6',
          ),
        ],
        unreadCounts: {
          'current_user_id_placeholder': 0,
          'user_5': 0,
          'user_6': 0
        },
        lastMessageAt: now.subtract(const Duration(hours: 2)),
        settings: ChatSettings(
          allowInvites: true,
          isPublic: true,
          maxParticipants: 50,
          messageRetention: 30,
        ),
        metadata: ChatMetadata(
          stats: ChatStats(
            totalMessages: 15,
            totalParticipants: 3,
            lastActivity: now.subtract(const Duration(hours: 2)),
          ),
        ),
        integrations: ChatIntegrations(),
        createdAt: now,
        updatedAt: now,
        lastMessage: LastMessage(
          content: 'Mrs. Angu Telma',
          type: 'TEXT',
          senderId: 'user_5',
          senderName: 'Mrs. Angu Telma',
          timestamp: now.subtract(const Duration(hours: 2)),
          status: MessageStatus.sent,
        ),
      ),
      Chat(
        id: '5',
        name: 'Mr. Ngah Owona',
        type: ChatType.personal,
        participants: ['current_user_id_placeholder', 'user_6'],
        createdBy: 'current_user_id_placeholder',
        userMetadata: [
          ParticipantMetadata(
            userId: 'current_user_id_placeholder',
            unreadCount: 0,
            isMuted: false,
            isPinned: false,
            notificationSettings: NotificationSettings(
              enabled: true,
              sound: true,
              vibration: true,
            ),
            nom: 'User',
            prenom: 'You',
            avatar: AppAssets.avatar,
            metadataId: 'meta_current_user_5',
          ),
          ParticipantMetadata(
            userId: 'user_6',
            unreadCount: 0,
            isMuted: false,
            isPinned: false,
            notificationSettings: NotificationSettings(
              enabled: true,
              sound: true,
              vibration: true,
            ),
            nom: 'Owona',
            prenom: 'Mr. Ngah',
            avatar: AppAssets.avatar,
            metadataId: 'meta_user_6_2',
          ),
        ],
        unreadCounts: {'current_user_id_placeholder': 0, 'user_6': 0},
        lastMessageAt: now.subtract(const Duration(hours: 6)),
        settings: ChatSettings(
          allowInvites: true,
          isPublic: false,
          maxParticipants: 2,
          messageRetention: 30,
        ),
        metadata: ChatMetadata(
          stats: ChatStats(
            totalMessages: 12,
            totalParticipants: 2,
            lastActivity: now.subtract(const Duration(hours: 6)),
          ),
        ),
        integrations: ChatIntegrations(),
        createdAt: now,
        updatedAt: now,
        lastMessage: LastMessage(
          content: 'good job',
          type: 'TEXT',
          senderId: 'user_6',
          senderName: 'Mr. Ngah Owona',
          timestamp: now.subtract(const Duration(hours: 6)),
          status: MessageStatus.sent,
        ),
      ),
      Chat(
        id: '6',
        name: 'Mrs. Angu Telma',
        type: ChatType.personal,
        participants: ['current_user_id_placeholder', 'user_5'],
        createdBy: 'current_user_id_placeholder',
        userMetadata: [
          ParticipantMetadata(
            userId: 'current_user_id_placeholder',
            unreadCount: 0,
            isMuted: false,
            isPinned: false,
            notificationSettings: NotificationSettings(
              enabled: true,
              sound: true,
              vibration: true,
            ),
            nom: 'User',
            prenom: 'You',
            avatar: AppAssets.avatar,
            metadataId: 'meta_current_user_6',
          ),
          ParticipantMetadata(
            userId: 'user_5',
            unreadCount: 0,
            isMuted: false,
            isPinned: false,
            notificationSettings: NotificationSettings(
              enabled: true,
              sound: true,
              vibration: true,
            ),
            nom: 'Telma',
            prenom: 'Mrs. Angu',
            avatar: AppAssets.avatar,
            metadataId: 'meta_user_5_2',
          ),
        ],
        unreadCounts: {'current_user_id_placeholder': 0, 'user_5': 0},
        lastMessageAt: now.subtract(const Duration(hours: 5)),
        settings: ChatSettings(
          allowInvites: true,
          isPublic: false,
          maxParticipants: 2,
          messageRetention: 30,
        ),
        metadata: ChatMetadata(
          stats: ChatStats(
            totalMessages: 9,
            totalParticipants: 2,
            lastActivity: now.subtract(const Duration(hours: 5)),
          ),
        ),
        integrations: ChatIntegrations(),
        createdAt: now,
        updatedAt: now,
        lastMessage: LastMessage(
          content: 'great',
          type: 'TEXT',
          senderId: 'user_5',
          senderName: 'Mrs. Angu Telma',
          timestamp: now.subtract(const Duration(hours: 5)),
          status: MessageStatus.sent,
        ),
      ),
      Chat(
        id: '7',
        name: 'Broadcast',
        type: ChatType.broadcast,
        participants: ['current_user_id_placeholder'],
        createdBy: 'current_user_id_placeholder',
        userMetadata: [
          ParticipantMetadata(
            userId: 'current_user_id_placeholder',
            unreadCount: 0,
            isMuted: false,
            isPinned: false,
            notificationSettings: NotificationSettings(
              enabled: true,
              sound: true,
              vibration: true,
            ),
            nom: 'User',
            prenom: 'You',
            avatar: AppAssets.avatar,
            metadataId: 'meta_current_user_7',
          ),
        ],
        unreadCounts: {'current_user_id_placeholder': 0},
        lastMessageAt: now,
        settings: ChatSettings(
          allowInvites: false,
          isPublic: false,
          maxParticipants: 1,
          messageRetention: 30,
        ),
        metadata: ChatMetadata(
          stats: ChatStats(
            totalMessages: 1,
            totalParticipants: 1,
            lastActivity: now,
          ),
        ),
        integrations: ChatIntegrations(),
        createdAt: now,
        updatedAt: now,
        lastMessage: LastMessage(
          content: 'This is a broadcast message',
          type: 'TEXT',
          senderId: 'current_user_id_placeholder',
          senderName: 'You',
          timestamp: now,
          status: MessageStatus.sent,
        ),
      ),
    ];
  }

  Future<List<Chat>> searchChats(String query) async {
    final chats = await getChats();
    return chats
        .where((chat) =>
            chat.name.toLowerCase().contains(query.toLowerCase()) ||
            (chat.lastMessage?.content
                    .toLowerCase()
                    .contains(query.toLowerCase()) ??
                false))
        .toList();
  }
}
