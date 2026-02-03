# 🎨 Visualisation - Flux Complet de Stockage des Messages

## 📊 Diagramme de Flux

```
┌────────────────────────────────────────────────────────────────┐
│                    SOCKET.IO SERVEUR                           │
│                                                                │
│  Utilisateur A envoie "Bonjour" à Utilisateur B               │
│                                                                │
└─────────────────────┬──────────────────────────────────────────┘
                      │
                      │ Émet événement "newMessage"
                      ↓
┌────────────────────────────────────────────────────────────────┐
│               NAVIGATEUR - UTILISATEUR B                        │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │              SOCKET SERVICE                              │ │
│  │  - Reçoit "newMessage" du serveur                       │ │
│  │  - Emet newMessageStream                                │ │
│  └──────────┬─────────────────────┬───────────────────────┘ │
│             │                     │                          │
│             ↓                     ↓                          │
│  ┌──────────────────────┐  ┌────────────────────────┐      │
│  │ MESSAGE REPOSITORY   │  │ CHATLIST REPOSITORY    │      │
│  │                      │  │                        │      │
│  │ _handleNewMessage()  │  │ _handleNewMessage()    │      │
│  │ ┌──────────────────┐ │  │ ┌──────────────────────┐│      │
│  │ │ 1. Normalise     │ │  │ │ 1. Récupère Chat    ││      │
│  │ │    isMe flag     │ │  │ │    depuis Hive      ││      │
│  │ │ (compare avec    │ │  │ │                      ││      │
│  │ │  matricule user) │ │  │ │ 2. Met à jour       ││      │
│  │ └──────────────────┘ │  │ │    lastMessage      ││      │
│  │                      │  │ │    et lastMessageAt ││      │
│  │ _addMessageToCache() │  │ │                      ││      │
│  │ ┌──────────────────┐ │  │ │ 3. Sauvegarde Chat  ││      │
│  │ │ 2. Ajoute au     │ │  │ │    dans Hive        ││      │
│  │ │    cache mémoire │ │  │ └──────────────────────┘│      │
│  │ │                  │ │  │                        │      │
│  │ │ 3. Trie par      │ │  │ 4. Notifie stream    │      │
│  │ │    timestamp     │ │  │    chatsStream       │      │
│  │ │                  │ │  │                        │      │
│  │ │ 4. 💾 Sauvegarde │ │  └────────┬───────────────┘      │
│  │ │    dans Hive     │ │           │                      │
│  │ │    (IMPORTANT!)  │ │           ↓                      │
│  │ │                  │ │  ┌──────────────────────┐       │
│  │ │ 5. Notifie       │ │  │   VIEWMODELS         │       │
│  │ │    messageStream │ │  │                      │       │
│  │ └──────────────────┘ │  │ ChatListViewModel    │       │
│  │                      │  │ ├─ notifyListeners() │       │
│  │ markMessageRead()    │  │ └─ chats mis à jour  │       │
│  │ ┌──────────────────┐ │  │                      │       │
│  │ │ 6. Marque comme  │ │  │ MessageViewModel    │       │
│  │ │    "read"        │ │  │ ├─ notifyListeners() │       │
│  │ │    automatiquement│ │  │ └─ messages mis à j  │       │
│  │ │                  │ │  └──────────────────────┘       │
│  │ │ 7. Sauvegarde    │ │           │                      │
│  │ │    statut Hive   │ │           ↓                      │
│  │ └──────────────────┘ │  ┌──────────────────────┐       │
│  │                      │  │      UI - WIDGETS    │       │
│  │                      │  │                      │       │
│  │                      │  │ ChatListScreen       │       │
│  │                      │  │ ├─ Affiche conv      │       │
│  │                      │  │ │  mise à jour       │       │
│  │                      │  │ │  lastMessage       │       │
│  │                      │  │ └─ Consumer rebuild  │       │
│  │                      │  │                      │       │
│  │                      │  │ ChatScreen           │       │
│  │                      │  │ ├─ Affiche nouveau   │       │
│  │                      │  │ │  message (gauche)  │       │
│  │                      │  │ │  car isMe=false    │       │
│  │                      │  │ └─ Consumer rebuild  │       │
│  │                      │  └──────────────────────┘       │
│  │                      │                                 │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │              HIVE DATABASE (Local)                   │ │
│  │                                                       │ │
│  │  messages_60f7b3b3b3b3b3b3b3b3b3b9: [               │ │
│  │    ✅ Message(                                       │ │
│  │      id: "msg1", isMe: true, content: "Salut"      │ │
│  │    ),                                               │ │
│  │    ✅ Message(                                       │ │
│  │      id: "6787b8...", isMe: false,                 │ │
│  │      content: "Bonjour", status: read              │ │
│  │    )  ← NOUVEAU MESSAGE SAUVEGARDÉ                 │ │
│  │  ]                                                   │ │
│  │                                                       │ │
│  │  60f7b3b3b3b3b3b3b3b3b3b9: {                        │ │
│  │    id: "60f7b3b3b3b3b3b3b3b3b3b9",                │ │
│  │    lastMessage: "Bonjour",                          │ │
│  │    lastMessageAt: 2026-02-03T10:05:00 ← MIS À J   │ │
│  │  }                                                   │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## 🔄 Comparaison Avant/Après

### AVANT (❌ Messages non persistés)

```
Socket.IO "newMessage"
    ↓
MessageRepository._handleNewMessage()
    ↓
_addMessageToCache()
    ├─ Cache mémoire ✅
    └─ Hive: ❌ NON SAUVEGARDÉ
    ↓
Listeners notifiés
    ↓
UI affichée ✅
    ↓
❌ Si l'app crash ou ferme:
   Les messages sont perdus!
```

### APRÈS (✅ Messages persistés)

```
Socket.IO "newMessage"
    ↓
MessageRepository._handleNewMessage()
    ↓
_addMessageToCache()
    ├─ Cache mémoire ✅
    └─ Hive: ✅ SAUVEGARDÉ MAINTENANT
    ↓
ChatListRepository._handleNewMessage()
    ├─ Chat récupéré depuis Hive ✅
    ├─ lastMessage mis à jour ✅
    └─ Chat sauvegardé dans Hive ✅
    ↓
Listeners notifiés
    ↓
ViewModels.notifyListeners()
    ↓
UI rafraîchie
    ↓
✅ Si l'app crash ou ferme:
   Les messages sont récupérés depuis Hive!
```

---

## 📝 Logs Visuels

### Réception d'un Message

```
┌─────────────────────────────────────────────────────────────┐
│ 🧩 [ChatListRepository] _handleNewMessage appelé             │
│ 📨 [MessageRepository._handleNewMessage] Nouveau message:    │
│    - conversationId: 60f7b3b3b3b3b3b3b3b3b3b9                │
│    - messageId: 6787b8c8d8e8f8g8h8i8j8k8l8                   │
│    - senderId: 534589D                                       │
│    - isMe (normalisé): false ← COMPARÉ AVEC MATRICULE      │
│    - content: Bonjour, comment vas-tu?...                   │
│                                                              │
│ 💾 [MessageRepository] Message ajouté au cache ET             │
│    sauvegardé dans Hive: 6787b8c8d8e8f8g8h8i8j8k8l8          │
│                                                              │
│ 👁️ [MessageRepository] Marquage message comme read:         │
│    6787b8c8d8e8f8g8h8i8j8k8l8                               │
│                                                              │
│ 💾 [ChatListRepository] Conversation trouvée dans Hive:       │
│    60f7b3b3b3b3b3b3b3b3b3b9                                 │
│    - lastMessageAt (avant): 2026-02-03T10:00:00             │
│    - lastMessage (avant): Salut!                            │
│                                                              │
│ ✅ [ChatListRepository] Message trouvé:                      │
│    conv=60f7b3b3b3b3b3b3b3b3b3b9, content=Bonjour...       │
│                                                              │
│ ✅ [ChatListRepository] lastMessage mis à jour pour          │
│    60f7b3b3b3b3b3b3b3b3b3b9                                 │
│                                                              │
│ 📨 Conversations mises à jour: 5                             │
│                                                              │
│ 🔔 notifyListeners() appelé - UI devrait se mettre à jour  │
│                                                              │
│ 🕐 ChatListViewModel: Rafraîchissement des dates             │
│ 🔔 notifyListeners() appelé - UI devrait se mettre à jour  │
│                                                              │
│ 🎨 [ChatTile] Build - 534589D: lastMessage="Bonjour..."    │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Points Clés de la Synchronisation

### 1️⃣ **Réception (newMessage)**

```
┌──────────────────────────────────────┐
│ Socket Event "newMessage"            │
│ contient: Message { ... }            │
└──────────┬───────────────────────────┘
           ↓
┌──────────────────────────────────────┐
│ MessageRepository._handleNewMessage()│
│ ├─ Normalise isMe                   │
│ ├─ Compare senderId vs matricule    │
│ └─ Ajoute au cache                  │
└──────────┬───────────────────────────┘
           ↓
┌──────────────────────────────────────┐
│ _addMessageToCache()                 │
│ ├─ Ajoute à List<Message>           │
│ ├─ Trie par timestamp               │
│ ├─ 💾 Sauvegarde dans Hive          │
│ └─ Notifie messageStream            │
└──────────┬───────────────────────────┘
           ↓
┌──────────────────────────────────────┐
│ ChatListRepository._handleNewMessage()
│ ├─ Récupère Chat depuis Hive        │
│ ├─ Met à jour lastMessage           │
│ ├─ 💾 Sauvegarde Chat dans Hive    │
│ └─ Notifie chatsStream              │
└──────────┬───────────────────────────┘
           ↓
┌──────────────────────────────────────┐
│ ViewModels notifiés                  │
│ ├─ MessageViewModel.notifyListeners()│
│ └─ ChatListViewModel.notifyListeners│
└──────────┬───────────────────────────┘
           ↓
┌──────────────────────────────────────┐
│ UI mise à jour                       │
│ ├─ ChatScreen: nouveau message      │
│ └─ ChatListScreen: dernier message  │
└──────────────────────────────────────┘
```

### 2️⃣ **Envoi (sendMessage → message_sent)**

```
┌──────────────────────────────────────┐
│ Utilisateur écrit et envoie          │
└──────────┬───────────────────────────┘
           ↓
┌──────────────────────────────────────┐
│ MessageRepository.sendMessage()      │
│ ├─ Crée temporaryId                 │
│ ├─ Ajoute au cache                  │
│ ├─ 💾 Sauvegarde dans Hive          │
│ └─ Émet "sendMessage" via Socket    │
└──────────┬───────────────────────────┘
           ↓
        (Serveur reçoit et traite)
           ↓
┌──────────────────────────────────────┐
│ Socket Event "message_sent"          │
│ contient: { temporaryId, messageId } │
└──────────┬───────────────────────────┘
           ↓
┌──────────────────────────────────────┐
│ MessageRepository._handleMessageSent│
│ ├─ Trouve message via temporaryId   │
│ ├─ Remplace par ID permanent        │
│ ├─ 💾 Sauvegarde dans Hive          │
│ └─ Notifie messageStream            │
└──────────┬───────────────────────────┘
           ↓
┌──────────────────────────────────────┐
│ ChatListRepository._handleMessageSent
│ ├─ Récupère Chat depuis Hive        │
│ ├─ Met à jour lastMessage           │
│ ├─ 💾 Sauvegarde Chat dans Hive    │
│ └─ Notifie chatsStream              │
└──────────┬───────────────────────────┘
           ↓
┌──────────────────────────────────────┐
│ ViewModels notifiés                  │
├─ MessageViewModel.notifyListeners() │
└─ ChatListViewModel.notifyListeners()│
└──────────┬───────────────────────────┘
           ↓
┌──────────────────────────────────────┐
│ UI mise à jour                       │
│ ├─ Message affiche à droite (isMe)  │
│ ├─ Status passe de "pending" → "sent"
│ └─ ChatList mise à jour             │
└──────────────────────────────────────┘
```

---

## 🧪 Scénario de Test Complet

### Test: Recevoir et Envoyer un Message

#### 1. État Initial

```
Hive - messages_conv1: []
Hive - conv1: { lastMessage: "Salut!" }
UI Chat: Affiche message précédent
UI ChatList: Affiche "Salut!"
```

#### 2. Utilisateur B envoie "Bonjour"

```
Socket "newMessage" reçu
    ↓
MessageRepository._handleNewMessage()
    ├─ isMe = false (senderId != matricule)
    ├─ _addMessageToCache()
    │   └─ 💾 Hive: messages_conv1 = [... ancien, nouveau]
    └─ markMessageRead(id, conv1)
        └─ 💾 Hive: message.status = read
    ↓
ChatListRepository._handleNewMessage()
    ├─ Récupère Chat depuis Hive
    └─ 💾 Hive: conv1.lastMessage = "Bonjour"
    ↓
ViewModels notifiés
    ↓
UI mise à jour
├─ ChatScreen: affiche "Bonjour" à GAUCHE ✅
└─ ChatListScreen: affiche "Bonjour" (dernière heure) ✅
```

#### 3. Utilisateur A répond "Salut toi!"

```
Utilisateur clique envoyer
    ↓
MessageRepository.sendMessage()
    ├─ temporaryId = "temp_123"
    ├─ isMe = true
    ├─ _addMessageToCache()
    │   └─ 💾 Hive: messages_conv1 = [..., Bonjour, Salut toi!]
    └─ Émet "sendMessage"
    ↓
UI immédiate
├─ ChatScreen: affiche "Salut toi!" à DROITE (gris = pending) ✅
└─ Socket attend confirmation
    ↓
Socket "message_sent" reçu
    ├─ messageId = "msg_789"
    └─ MessageRepository._handleMessageSent()
        ├─ Trouve message via temp_123
        ├─ id = "msg_789", status = sent
        └─ 💾 Hive: messages_conv1[X] = { id: msg_789, status: sent }
    ↓
UI mise à jour
├─ ChatScreen: "Salut toi!" passe au vert (sent) ✅
└─ ChatListScreen: "Salut toi!" affichée ✅
    ↓
💾 Hive État Final:
├─ messages_conv1: [
│    { id: msg1, isMe: true, content: "Salut", status: read },
│    { id: msg2, isMe: false, content: "Bonjour", status: read },
│    { id: msg_789, isMe: true, content: "Salut toi!", status: sent }
│  ]
└─ conv1: {
     lastMessage: "Salut toi!",
     lastMessageAt: 2026-02-03T10:10:00
   }
```

#### 4. Fermeture et Réouverture de l'App

```
App fermée
    ↓
Cache mémoire supprimé ❌
Socket.IO déconnecté ❌
    ↓
App rouverte
    ↓
ChatListViewModel.loadConversations()
    ├─ ChatListRepository.loadConversations()
    │   └─ HiveService.getChats()
    │       └─ 💾 Récupère conversations depuis Hive
    │           ├─ conv1.lastMessage = "Salut toi!" ✅
    │           └─ Affiche dans ChatList
    └─ notifyListeners()
        └─ UI affiche chat list avec messages persistés ✅
    ↓
Utilisateur clique sur conv1
    ↓
MessageViewModel.loadMessages(conv1)
    ├─ MessageRepository.getMessages(conv1)
    │   └─ HiveService.getMessagesForConversation(conv1)
    │       └─ 💾 Récupère: [Salut, Bonjour, Salut toi!]
    └─ notifyListeners()
        └─ UI affiche tous les messages persistés ✅
            ├─ "Salut" à droite (isMe = true) ✅
            ├─ "Bonjour" à gauche (isMe = false) ✅
            └─ "Salut toi!" à droite (isMe = true) ✅
```

---

## ✨ Résumé de la Solution

| Aspect                     | Avant ❌              | Après ✅               |
| -------------------------- | --------------------- | ---------------------- |
| **Sauvegarde newMessage**  | Cache mémoire seul    | Cache + Hive           |
| **Sauvegarde messageSent** | Cache mémoire seul    | Cache + Hive           |
| **Persistance**            | Perdue au redémarrage | Persistante            |
| **Normalisation isMe**     | Via matricule         | Via matricule          |
| **Chat lastMessage**       | Mis à jour en mémoire | Hive + notifyListeners |
| **Marquage read**          | Automatique           | Automatique            |
| **Logs**                   | Minimaux              | Détaillés              |
