import 'package:flutter/material.dart';
import 'package:ngomna_chat/views/widgets/common/auth_form_screen.dart';
import 'package:ngomna_chat/core/routes/app_routes.dart';

class SelectPostScreen extends StatelessWidget {
  const SelectPostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthFormScreen(
      title: 'Please enter your\nworking post below',
      inputHint: 'Type post here!',
      onSubmit: (post) {
        // TODO: Sauvegarder le post (ViewModel)
        Navigator.pushNamed(context, AppRoutes.home);
      },
    );
  }
}
