import 'dart:async';

/// 📚 EXEMPLE: Patterns pour optimistic updates
///
/// Ce fichier montre les patterns recommandés.
/// À adapter selon votre modèle Message réel.
///
/// Pattern complet:
/// 1. Optimistic update dans Hive (immédiat)
/// 2. Émettre via stream (UI se met à jour)
/// 3. Appel serveur asynchrone
/// 4. Mettre à jour avec vraie réponse
/// 5. En cas d'erreur, rollback ou marquer comme failed

/// PSEUDO-IMPLÉMENTATION
/// (À adapter avec vos vrais modèles)

class OptimisticPatternExample {
  // ════════════════════════════════════════════════════════════════
  // PATTERN 1: Envoi de Message avec Optimistic Update
  // ════════════════════════════════════════════════════════════════

  /// Envoie un message avec optimistic update
  ///
  /// Flux:
  /// 1. Créer le message avec status 'sending'
  /// 2. Sauvegarder dans Hive (optimistic)
  /// 3. Émettre via stream (UI se met à jour)
  /// 4. Appel serveur
  /// 5. Mettre à jour avec réponse du serveur
  ///
  /// En cas d'erreur:
  /// - Marquer comme 'failed'
  /// - Réémettre pour notifier l'UI
  /// - Laisser Hive pour retry au prochain démarrage
  Future<void> exampleSendMessage({
    required String conversationId,
    required String content,
    required String senderId,
  }) async {
    print('═══════════════════════════════════════════════════════════');
    print('           PATTERN: Optimistic Message Send                 ');
    print('═══════════════════════════════════════════════════════════\n');

    // ────────────────────────────────────────────────────────────
    // ÉTAPE 1: Créer le message local avec ID temporaire
    // ────────────────────────────────────────────────────────────
    final tempMessageId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    print('📝 ÉTAPE 1: Créer message optimiste');
    print('   ID temporaire: $tempMessageId');
    print('   Status: sending');
    print('   Metadata: {optimistic: true}\n');

    try {
      // ────────────────────────────────────────────────────────────
      // ÉTAPE 2: Sauvegarder dans Hive (optimistic)
      // ────────────────────────────────────────────────────────────
      print('💾 ÉTAPE 2: Sauvegarder dans Hive');
      print('   await messageBox.put(tempMessageId, message)');
      print('   ✅ Message persisté localement\n');

      // ────────────────────────────────────────────────────────────
      // ÉTAPE 3: Émettre via stream (UI se met à jour immédiatement)
      // ────────────────────────────────────────────────────────────
      print('📤 ÉTAPE 3: Émettre via messageStream');
      print('   streamManager.emitMessage(MessageEvent(');
      print('       messageId: $tempMessageId,');
      print('       status: "sending",');
      print('       context: "optimistic"');
      print('   ))');
      print('   ✅ UI affiche le message IMMÉDIATEMENT\n');

      // ────────────────────────────────────────────────────────────
      // ÉTAPE 4: Appel serveur asynchrone (EN ARRIÈRE-PLAN)
      // ────────────────────────────────────────────────────────────
      print('🌐 ÉTAPE 4: Appel serveur (async)');
      print('   await api.sendMessage(message)');
      print('   ⏳ En attente... (2-5 secondes typiquement)\n');

      // Simuler l'appel serveur
      await Future.delayed(Duration(seconds: 2));

      final response = MessageResponse(
        messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        status: 'sent',
        timestamp: DateTime.now(),
      );

      print('✅ Réponse serveur reçue');
      print('   messageId réel: ${response.messageId}');
      print('   status: ${response.status}\n');

      // ────────────────────────────────────────────────────────────
      // ÉTAPE 5: Mettre à jour avec la vraie réponse
      // ────────────────────────────────────────────────────────────
      print('🔄 ÉTAPE 5: Synchroniser avec réponse réelle');
      print('   await messageBox.delete(tempMessageId)');
      print('   await messageBox.put(${response.messageId}, realMessage)');
      print('   ✅ Hive mis à jour avec ID réel\n');

      // ────────────────────────────────────────────────────────────
      // ÉTAPE 6: Émettre le message final
      // ────────────────────────────────────────────────────────────
      print('📬 ÉTAPE 6: Émettre le message final');
      print('   streamManager.emitMessage(MessageEvent(');
      print('       messageId: ${response.messageId},');
      print('       status: "sent",');
      print('       context: "sent"');
      print('   ))');
      print('   ✅ UI met à jour avec le message final\n');

      // ────────────────────────────────────────────────────────────
      // ÉTAPE 7: Mettre à jour la conversation
      // ────────────────────────────────────────────────────────────
      print('💬 ÉTAPE 7: Mettre à jour conversation');
      print('   conversationBox.put(convId, conv.copyWith(');
      print('       lastMessage: $content,');
      print('       lastMessageTime: now,');
      print('       lastMessageSenderId: $senderId');
      print('   ))');
      print('   ✅ Derniers messages mis à jour\n');

      print('═══════════════════════════════════════════════════════════');
      print('           SUCCÈS: Message envoyé et synchronisé             ');
      print('═══════════════════════════════════════════════════════════\n');
    } catch (error) {
      // ────────────────────────────────────────────────────────────
      // GESTION D'ERREUR: Marquer comme failed pour retry
      // ────────────────────────────────────────────────────────────
      print('❌ ERREUR: $error\n');

      print('🔧 GESTION D\'ERREUR:');
      print('   1. Marquer le message comme failed:');
      print('      await messageBox.put(tempMessageId, failedMessage)');
      print('   2. Notifier l\'UI:');
      print('      streamManager.emitMessage(MessageEvent(');
      print('          status: "failed",');
      print('          context: "error"');
      print('      ))');
      print('   3. Laisser dans Hive pour retry au prochain démarrage\n');

      print('   ✅ Le message reste local en attente de retry');
      print('   ✅ Au prochain démarrage: syncHiveToStreams()');
      print('      → Remet en file d\'attente les messages failed');
      print('      → Repository retry automatiquement\n');

      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // PATTERN 2: Marquer comme Lus avec Optimistic Update
  // ════════════════════════════════════════════════════════════════

  Future<void> exampleMarkAsRead({
    required List<String> messageIds,
  }) async {
    print('═══════════════════════════════════════════════════════════');
    print('          PATTERN: Optimistic Mark As Read                   ');
    print('═══════════════════════════════════════════════════════════\n');

    try {
      // ────────────────────────────────────────────────────────────
      // ÉTAPE 1: Mettre à jour dans Hive (optimiste)
      // ────────────────────────────────────────────────────────────
      print('💾 ÉTAPE 1: Mettre à jour status dans Hive');
      print('   for (messageId in $messageIds) {');
      print('       message.status = "read"');
      print('       await messageBox.put(messageId, message)');
      print('   }');
      print('   ✅ ${messageIds.length} messages mis à jour\n');

      // ────────────────────────────────────────────────────────────
      // ÉTAPE 2: Émettre les changements de status
      // ────────────────────────────────────────────────────────────
      print('📊 ÉTAPE 2: Émettre les changements');
      print('   for (messageId in $messageIds) {');
      print('       streamManager.emitMessageStatus(');
      print('           MessageStatusEvent(status: "read")');
      print('       )');
      print('   }');
      print('   ✅ Checkmarks mis à jour immédiatement\n');

      // ────────────────────────────────────────────────────────────
      // ÉTAPE 3: Appel serveur
      // ────────────────────────────────────────────────────────────
      print('🌐 ÉTAPE 3: Confirmer au serveur');
      print('   await api.markAsRead(messageIds)');
      print('   ⏳ En attente...\n');

      await Future.delayed(Duration(milliseconds: 500));

      print('✅ Serveur confirmé\n');

      // ────────────────────────────────────────────────────────────
      // ÉTAPE 4: Rien à faire si succès
      // ────────────────────────────────────────────────────────────
      print('✅ ÉTAPE 4: Synchronisation complète');
      print('   (Rien à faire si succès, déjà dans Hive)\n');

      print('═══════════════════════════════════════════════════════════');
      print('           SUCCÈS: Messages marqués comme lus                ');
      print('═══════════════════════════════════════════════════════════\n');
    } catch (error) {
      print('❌ ERREUR: $error\n');
      print('💡 OPTIONS:');
      print('   A) Ignorer (le message restera "read" localement)');
      print('   B) Rollback (restaurer l\'ancien status)\n');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // PATTERN 3: Retry des Messages Failed
  // ════════════════════════════════════════════════════════════════

  Future<void> exampleRetryFailedMessages() async {
    print('═══════════════════════════════════════════════════════════');
    print('             PATTERN: Retry Failed Messages                  ');
    print('═══════════════════════════════════════════════════════════\n');

    print('🔄 ÉTAPE 1: Chercher les messages failed dans Hive');
    print('   final failed = messageBox.values');
    print('       .where((m) => m.status == "failed")');
    print('       .toList();');
    print('   → Trouvé 3 messages\n');

    print('📨 ÉTAPE 2: Réémettre via streams');
    print('   for (final message in failed) {');
    print('       streamManager.emitMessage(MessageEvent(');
    print('           type: "pending",');
    print('           status: "failed"');
    print('       ))');
    print('   }');
    print('   → 3 messages réémis\n');

    print('🔄 ÉTAPE 3: Repository retry l\'envoi');
    print('   for (final message in failed) {');
    print('       try {');
    print('           await sendMessage(message)');
    print('       } catch (e) {');
    print('           // Laisser pour retry ultérieur');
    print('       }');
    print('   }');
    print('   → Succès: 2/3, Failed: 1/3\n');

    print('═══════════════════════════════════════════════════════════');
    print('           SUCCÈS: Retry effectué automatiquement             ');
    print('═══════════════════════════════════════════════════════════\n');
  }
}

// ════════════════════════════════════════════════════════════════
// MODÈLES D'AIDE (À adapter avec vos vrais modèles)
// ════════════════════════════════════════════════════════════════

/// Réponse du serveur après envoi de message
class MessageResponse {
  final String messageId; // ID réel du serveur
  final String status; // 'sent', 'delivered', etc.
  final DateTime timestamp;

  MessageResponse({
    required this.messageId,
    required this.status,
    required this.timestamp,
  });
}
