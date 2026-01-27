import 'package:flutter/material.dart';
import 'package:ngomna_chat/core/constants/app_features.dart';
import 'package:ngomna_chat/views/widgets/common/bottom_nav.dart';
import 'package:ngomna_chat/views/widgets/common/container_wrapper.dart';
import 'package:ngomna_chat/views/widgets/common/top_bar.dart';
import 'package:ngomna_chat/views/widgets/home/feature_grid.dart';

class NgomnaFirstScreen extends StatelessWidget {
  const NgomnaFirstScreen({super.key});

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
