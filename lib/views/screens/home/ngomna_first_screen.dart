import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:ngomna_chat/core/constants/app_features.dart';
import 'package:ngomna_chat/views/widgets/common/bottom_nav.dart';
import 'package:ngomna_chat/views/widgets/common/container_wrapper.dart';
import 'package:ngomna_chat/views/widgets/common/top_bar.dart';
import 'package:ngomna_chat/views/widgets/home/feature_grid.dart';
import 'package:ngomna_chat/data/services/socket_service.dart';
import 'package:ngomna_chat/viewmodels/auth_viewmodel.dart';

class NgomnaFirstScreen extends StatefulWidget {
  const NgomnaFirstScreen({Key? key}) : super(key: key);

  @override
  _NgomnaFirstScreenState createState() => _NgomnaFirstScreenState();
}

class _NgomnaFirstScreenState extends State<NgomnaFirstScreen> {
  late SocketService _socketService;
  late AuthViewModel _authViewModel;

  // État des conversations
  Map<String, dynamic>? _conversationsData;
  int _totalUnreadMessages = 0;
  int _unreadConversations = 0;
  bool _isLoadingConversations = true;
  String? _error;

  // Abonnements aux streams
  StreamSubscription? _conversationsSubscription;
  StreamSubscription? _newMessageSubscription;
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();

    // Attendre que le widget soit monté avant d'accéder aux providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSocketListeners();
    });
  }

  void _initializeSocketListeners() {
    _socketService = Provider.of<SocketService>(context, listen: false);
    _authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    // Vérifier si l'utilisateur est authentifié Socket.IO
    if (!_socketService.isAuthenticated) {
      print('⚠️ Utilisateur non authentifié Socket.IO sur home screen');
      return;
    }

    print('🏠 Home Screen: Écoute des conversations...');

    // Écouter les conversations envoyées automatiquement
    _conversationsSubscription = _socketService.conversationsStream.listen(
      _handleConversationsUpdate,
      onError: (error) {
        print('❌ Erreur stream conversations: $error');
        setState(() {
          _error = 'Erreur de connexion aux conversations';
        });
      },
    );

    // Écouter les nouveaux messages pour mettre à jour les badges
    _newMessageSubscription = _socketService.messageStream.listen((message) {
      print('📩 Nouveau message reçu sur home screen');
      _incrementUnreadCount();
    });

    // Écouter les changements d'authentification
    _authSubscription = _socketService.authStream.listen((isAuthenticated) {
      if (!isAuthenticated) {
        print('🔒 Déconnexion Socket.IO détectée');
        setState(() {
          _conversationsData = null;
          _totalUnreadMessages = 0;
          _unreadConversations = 0;
        });
      }
    });

    // Demander explicitement les conversations si pas reçues automatiquement
    Future.delayed(const Duration(seconds: 3), () {
      if (_conversationsData == null && _socketService.isAuthenticated) {
        print('🔄 Demande explicite des conversations...');
        _requestConversations();
      }
    });
  }

  /// Gérer la mise à jour des conversations
  void _handleConversationsUpdate(Map<String, dynamic> data) {
    print('💬 Conversations mises à jour reçues');

    // Compter le nombre réel de conversations
    int conversationCount = 0;
    if (data['conversations'] is List) {
      conversationCount = (data['conversations'] as List).length;
    } else if (data['categorized'] is Map) {
      final categorized = data['categorized'] as Map<String, dynamic>;
      for (final category in categorized.values) {
        if (category is List) {
          conversationCount += category.length;
        }
      }
    }

    print('🔄 Mise à jour des conversations dans NgomnaFirstScreen');
    print('📦 Clés reçues: ${data.keys.join(", ")}');
    print('💬 Nombre de conversations: $conversationCount');

    print('🔍 Conversations actuelles: \n');
    print(_conversationsData != null
        ? _conversationsData
        : 'Aucune conversation disponible');

    setState(() {
      _isLoadingConversations = false;
      _error = null;
      _conversationsData = data;

      // Extraire les statistiques
      if (data['stats'] != null) {
        final stats = Map<String, dynamic>.from(data['stats']);
        _totalUnreadMessages = stats['totalUnreadMessages'] as int? ?? 0;
        _unreadConversations = stats['unread'] as int? ?? 0;
      } else if (data['totalUnreadMessages'] != null) {
        _totalUnreadMessages = data['totalUnreadMessages'] as int;
        _unreadConversations = data['unreadConversations'] as int? ?? 0;
      }

      print(
          '📊 Stats: $_totalUnreadMessages messages non lus, $_unreadConversations conversations non lues');
    });
  }

  /// Demander explicitement les conversations
  Future<void> _requestConversations() async {
    if (!_socketService.isAuthenticated) return;

    setState(() {
      _isLoadingConversations = true;
    });

    try {
      // Le SocketService a une méthode pour demander les conversations
      // Note: La méthode _getConversations() dans SocketService est privée
      // On pourrait l'exposer ou utiliser un autre mécanisme

      // Pour l'instant, on attend juste les conversations automatiques
      await Future.delayed(const Duration(seconds: 5));

      if (_conversationsData == null) {
        setState(() {
          _error = 'Aucune conversation reçue';
          _isLoadingConversations = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur chargement conversations';
        _isLoadingConversations = false;
      });
      print('❌ Erreur demande conversations: $e');
    }
  }

  /// Incrémenter le compteur de messages non lus
  void _incrementUnreadCount() {
    setState(() {
      _totalUnreadMessages++;
    });
  }

  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    _newMessageSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const TopBar(),
            Expanded(
              child: Center(
                child: ContainerWrapper(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.02,
                      vertical: size.height * 0.05,
                    ),
                    child: FeatureGrid(
                      features: AppFeatures.homeFeatures,
                    ),
                  ),
                ),
              ),
            ),
            const BottomNav(),
          ],
        ),
      ),
    );
  }
}
