# ✅ Vérification - Stockage Automatique des Messages

## 📋 Flux Complet de Stockage des Messages

### 1️⃣ **Réception d'un Message via Socket.IO**

```
Socket.IO Event "newMessage"
        ↓
SocketService.newMessageStream
        ↓
MessageRepository._handleNewMessage()
```

### 2️⃣ **Traitement dans MessageRepository**

```dart
// A. Normaliser le flag isMe
void _handleNewMessage(Message message) {
  final normalizedMessage = message.copyWith(
    isMe: _isMessageFromMe(message)  // ✅ Compare senderId vs matricule
  );

  // B. Ajouter au cache ET sauvegarder dans Hive
  _addMessageToCache(conversationId, normalizedMessage);

  // C. Marquer comme lu si ce n'est pas notre message
  if (!normalizedMessage.isMe) {
    markMessageRead(id, conversationId);
  }
}
```

### 3️⃣ **Sauvegarde dans Hive**

```dart
void _addMessageToCache(String conversationId, Message message) {
  // A. Ajouter à la liste en mémoire
  messages.add(message);
  messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

  // B. 💾 SAUVEGARDER DANS HIVE
  _hiveService.saveMessages(messages);  // ✅ NOUVEAU

  // C. Notifier les listeners
  if (_messageStreams.containsKey(conversationId)) {
    _messageStreams[conversationId]!.add(messages);
  }
}
```

### 4️⃣ **Mise à Jour de la Liste des Conversations**

```
newMessage Event
        ↓
ChatListRepository._handleNewMessage()
        ↓
Récupère le Chat depuis Hive
        ↓
Met à jour Chat.lastMessage et Chat.lastMessageAt
        ↓
Sauvegarde le Chat dans Hive
        ↓
Notifie les listeners du stream
        ↓
ChatListViewModel.notifyListeners()
        ↓
Chat list UI se rafraîchit
```

---

## 🔍 Points de Vérification

### A. **Listeners Socket.IO**

✅ `MessageRepository._setupSocketListeners()` appelé au démarrage

- Écoute `newMessageStream`
- Écoute `messageSentStream`
- Écoute `messagesLoadedStream`
- Écoute `messageErrorStream`

### B. **Sauvegarde Automatique dans Hive**

✅ Trois points de sauvegarde:

1. **newMessage Event** → `_addMessageToCache()` → `_hiveService.saveMessages()`
2. **messageSent Event** → `_handleMessageSent()` → `_hiveService.saveMessages()`
3. **messagesLoaded Event** → `_handleMessagesLoaded()` → `_hiveService.saveMessages()`

### C. **Normalisation du Flag isMe**

✅ Dans `_handleNewMessage()`:

```dart
// Compare senderId avec matricule de l'utilisateur
final normalizedMessage = message.copyWith(isMe: _isMessageFromMe(message));
```

Trois niveaux de comparaison:

1. `senderId == user.matricule` (principal)
2. `senderMatricule == user.matricule` (fallback)
3. `senderId == user.id` (fallback)

### D. **Marquage Automatique du Message**

✅ Si le message n'est pas de nous:

```dart
if (!normalizedMessage.isMe && normalizedMessage.id.isNotEmpty) {
  markMessageRead(id, conversationId);
}
```

---

## 📊 Logs de Vérification

Lors de la réception d'un message, vous devez voir:

```
🧩 [ChatListRepository] _handleNewMessage appelé
✅ Message trouvé: conv=60f7b3b3b3b3b3b3b3b3b3b9, content=...
✅ lastMessage mis à jour pour 60f7b3b3b3b3b3b3b3b3b3b9
💾 [MessageRepository] Message ajouté au cache ET sauvegardé dans Hive: message_id
👁️ Marquage message comme read: message_id
🔔 notifyListeners() appelé - UI devrait se mettre à jour
```

---

## 🔄 Flux Complet d'une Conversation

### A. Utilisateur se connecte

```
1. AuthViewModel.login()
2. StorageService.setUser() → matricule sauvegardé
3. ChatListRepository.initializeWithAuth()
4. Socket.IO se connecte
```

### B. ChatListRepository reçoit les conversations

```
1. Socket Event "conversationsLoaded"
2. ChatListRepository._handleConversationsLoaded()
3. HiveService.saveChats() → Conversations en Hive
4. notifyListeners() → Chat list affichée
```

### C. Utilisateur ouvre une conversation

```
1. ChatScreen appelé avec conversationId
2. MessageRepository.getMessages()
3. Cherche dans Hive d'abord
4. Si vide: Socket.IO.getMessages()
5. Messages sauvegardés dans Hive + cache mémoire
```

### D. Message arrive en temps réel

```
1. Socket Event "newMessage"
2. MessageRepository._handleNewMessage()
   - Normalise isMe
   - Ajoute au cache
   - Sauvegarde dans Hive ✅ NOUVEAU
3. ChatListRepository._handleNewMessage()
   - Récupère Chat depuis Hive
   - Met à jour lastMessage
   - Sauvegarde Chat dans Hive
4. UI se met à jour (chat list + conversation)
```

---

## 💾 Données Persistantes

### Hive Boxes

```
_messagesBox
  ├─ Clé: "messages_60f7b3b3b3b3b3b3b3b3b3b9" (conversationId)
  ├─ Valeur: List<Message>
  └─ Mise à jour: newMessage, messageSent, messagesLoaded

_chatsBox
  ├─ Clé: "60f7b3b3b3b3b3b3b3b3b3b9" (conversationId)
  ├─ Valeur: Chat (contient lastMessage)
  └─ Mise à jour: conversationsLoaded, newMessage, messageSent
```

### SharedPreferences

```
user → JSON de l'utilisateur connecté (matricule, id, etc)
access_token → Token JWT
refresh_token → Token de refresh
```

---

## ✅ Checklist Finale

- [x] MessageRepository sauvegarde les messages reçus dans Hive
- [x] ChatListRepository met à jour lastMessage dans les chats
- [x] Flag isMe est normalisé via comparaison matricule
- [x] Messages sont marqués comme "read" automatiquement
- [x] Conversations sont sauvegardées au démarrage
- [x] Listeners Socket.IO sont configurés dans les repositories
- [x] Hive est source de vérité pour la persistance
- [x] Streams notifient les ViewModels des changements

---

## 🚀 Prochaines Étapes

1. Tester avec l'app en lisant les logs de Hive
2. Vérifier que les messages persistent après fermeture/réouverture
3. Valider que la liste des chats se met à jour correctement
4. Tester le marquage automatique des messages comme "read"
