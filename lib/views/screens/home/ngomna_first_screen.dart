import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:ngomna_chat/core/constants/app_features.dart';
import 'package:ngomna_chat/views/widgets/common/bottom_nav.dart';
import 'package:ngomna_chat/views/widgets/common/container_wrapper.dart';
import 'package:ngomna_chat/views/widgets/common/top_bar.dart';
import 'package:ngomna_chat/views/widgets/home/feature_grid.dart';
import 'package:ngomna_chat/data/services/socket_service.dart';
import 'package:ngomna_chat/data/services/chat_storage_orchestrator.dart';
import 'package:ngomna_chat/viewmodels/auth_viewmodel.dart';

class NgomnaFirstScreen extends StatefulWidget {
  const NgomnaFirstScreen({Key? key}) : super(key: key);

  @override
  _NgomnaFirstScreenState createState() => _NgomnaFirstScreenState();
}

class _NgomnaFirstScreenState extends State<NgomnaFirstScreen> {
  late SocketService _socketService;
  late AuthViewModel _authViewModel;
  ChatStorageOrchestrator? _storageOrchestrator;
  StreamSubscription<bool>? _authSubscription;

  // État des conversations
  Map<String, dynamic>? _conversationsData;
  int _totalUnreadMessages = 0;
  int _unreadConversations = 0;
  bool _isLoadingConversations = true;
  String? _error;

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

    // Écouter les changements d'authentification
    _authSubscription?.cancel();
    _authSubscription =
        _socketService.authChangedStream.listen((isAuthenticated) {
      if (isAuthenticated) {
        _onSocketAuthenticated();
      }
    });

    // Vérifier si l'utilisateur est déjà authentifié Socket.IO
    if (!_socketService.isAuthenticated) {
      print('⚠️ Utilisateur non authentifié Socket.IO sur home screen');
      return;
    }

    _onSocketAuthenticated();
  }

  void _onSocketAuthenticated() {
    print('🏠 Home Screen: Écoute des conversations...');

    // Initialiser l'orchestrateur juste après la connexion
    _storageOrchestrator ??=
        ChatStorageOrchestrator(_socketService.streamManager);
    _storageOrchestrator!.setupStreamToHiveBindings();
    _storageOrchestrator!.syncHiveToStreams();

    // Demander explicitement les conversations si pas reçues automatiquement
    Future.delayed(const Duration(seconds: 3), () {
      // if (_conversationsData == null && _socketService.isAuthenticated) {
      //   print('🔄 Demande explicite des conversations...');
      //   _requestConversations();
      // }
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

  @override
  void dispose() {
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
