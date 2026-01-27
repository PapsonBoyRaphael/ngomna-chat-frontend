import 'package:flutter/material.dart';
import 'package:ngomna_chat/data/models/feature_model.dart';

class FeatureCard extends StatelessWidget {
  final Feature feature;

  const FeatureCard({
    super.key,
    required this.feature,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Taille du bloc
    final double cardSize = size.width * 0.40;
    final double borderRadius = cardSize * 0.22;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, feature.route);
      },
      child: Center(
        child: Container(
          width: cardSize,
          height: cardSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color:
                    const Color.fromARGB(255, 207, 207, 207).withOpacity(0.54),
                offset: const Offset(0, 2),
                blurRadius: 6,
                spreadRadius: -3,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.asset(
              feature.iconPath,
              fit: BoxFit.cover,
              width: cardSize,
              height: cardSize,
            ),
          ),
        ),
      ),
    );
  }
}
