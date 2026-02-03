import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:ngomna_chat/views/widgets/common/auth_form_screen.dart';
import 'package:ngomna_chat/core/routes/app_routes.dart';
import 'package:ngomna_chat/viewmodels/auth_viewmodel.dart';
import 'package:ngomna_chat/data/services/socket_service.dart';
import 'package:ngomna_chat/data/services/storage_service.dart';

class EnterMatriculeScreen extends StatelessWidget {
  const EnterMatriculeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: true);
    final socketService = Provider.of<SocketService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);

    return AuthFormScreen(
      title: 'Please enter your\nmatricule below',
      inputHint: 'Matricule',
      isLoading: authViewModel.isLoading,
      errorMessage: authViewModel.error,
      successMessage: authViewModel.successMessage,
      onSubmit: (matricule) async {
        // Set matricule in ViewModel
        authViewModel.setMatriculeInput(matricule);

        // Attempt HTTP login
        final success = await authViewModel.login();

        if (success) {
          // Clear any messages before navigation
          authViewModel.clearMessages();

          try {
            // 🔄 Étape 2: Authentification Socket.IO
            final user = authViewModel.currentUser!;
            final token = await storageService.getAccessToken();

            if (token == null || token.isEmpty) {
              authViewModel.setError('Token d\'authentification manquant');
              return;
            }

            print('🔐 Tentative d\'authentification Socket.IO...');

            // Attendre que le socket soit connecté
            if (!socketService.isConnected) {
              print('⏳ En attente de connexion Socket.IO...');
              await _waitForSocketConnection(socketService);
            }

            // Authentifier avec le socket
            await socketService.authenticateWithUser(user, token);

            // Attendre la confirmation d'authentification Socket.IO
            print('⏳ En attente de confirmation Socket.IO...');
            final socketAuthSuccess =
                await _waitForSocketAuthentication(socketService);

            if (!socketAuthSuccess) {
              authViewModel.setError('Échec d\'authentification Socket.IO');
              return;
            }

            print('✅ Double authentification réussie !');

            // Navigate to home on successful dual authentication
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (route) => false,
            );
          } catch (e) {
            print('❌ Erreur authentification Socket.IO: $e');
            authViewModel.setError('Erreur de connexion en temps réel');
          }
        }
        // If login fails, error is already shown by ViewModel
      },
      onCancel: () {
        // Clear any error/success messages
        authViewModel.clearMessages();
      },
    );
  }

  /// Attendre que le socket soit connecté
  Future<void> _waitForSocketConnection(SocketService socketService,
      {int maxRetries = 10}) async {
    for (int i = 0; i < maxRetries; i++) {
      if (socketService.isConnected) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    throw TimeoutException('Connexion Socket.IO timeout');
  }

  /// Attendre l'authentification Socket.IO
  Future<bool> _waitForSocketAuthentication(SocketService socketService,
      {int timeoutSeconds = 10}) async {
    final completer = Completer<bool>();

    // Écouter les événements d'authentification
    final subscription =
        socketService.authChangedStream.listen((isAuthenticated) {
      if (!completer.isCompleted) {
        completer.complete(isAuthenticated);
      }
    });

    try {
      // Attendre avec timeout
      return await completer.future.timeout(Duration(seconds: timeoutSeconds));
    } on TimeoutException {
      print('⏰ Timeout authentification Socket.IO');
      return false;
    } catch (e) {
      print('❌ Erreur attente authentification: $e');
      return false;
    } finally {
      // Annuler l'abonnement
      subscription.cancel();
    }
  }
}
