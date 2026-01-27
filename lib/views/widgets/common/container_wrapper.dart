import 'package:flutter/material.dart';

/// Widget réutilisable pour le container blanc avec ombre
class ContainerWrapper extends StatelessWidget {
  final Widget child;

  const ContainerWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: size.width * 0.90,
      height: size.height * 0.75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        border: Border.all(
          color: Colors.black.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 40,
            spreadRadius: 5,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: child,
    );
  }
}
