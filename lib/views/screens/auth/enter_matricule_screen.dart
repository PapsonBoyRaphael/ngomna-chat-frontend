import 'package:flutter/material.dart';
import 'package:ngomna_chat/views/widgets/common/auth_form_screen.dart';
import 'package:ngomna_chat/core/routes/app_routes.dart';

class EnterMatriculeScreen extends StatelessWidget {
  const EnterMatriculeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthFormScreen(
      title: 'Please enter your\nmatricule below',
      inputHint: 'Matricule',
      onSubmit: (matricule) {
        // TODO: Sauvegarder le matricule (ViewModel)
        Navigator.pushNamed(context, AppRoutes.selectPost);
      },
    );
  }
}
