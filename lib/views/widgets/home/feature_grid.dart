import 'package:flutter/material.dart';
import 'package:ngomna_chat/data/models/feature_model.dart';
import 'package:ngomna_chat/views/widgets/home/feature_card.dart';

class FeatureGrid extends StatelessWidget {
  final List<Feature> features;

  const FeatureGrid({
    super.key,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double gridWidth = constraints.maxWidth;
        final double gridHeight = constraints.maxHeight;

        final double cardSize = (gridWidth - 24) / 2;
        final double totalGridHeight = (cardSize * 2) + 24;

        return Center(
          child: SizedBox(
            width: gridWidth,
            height: totalGridHeight.clamp(0, gridHeight),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 0,
                crossAxisSpacing: 0,
                childAspectRatio: 1,
              ),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: features.length,
              itemBuilder: (context, index) {
                return FeatureCard(feature: features[index]);
              },
            ),
          ),
        );
      },
    );
  }
}
