import 'package:flutter/material.dart';
import 'package:ngomna_chat/views/widgets/common/top_bar.dart';
import 'package:ngomna_chat/views/widgets/common/bottom_nav.dart';
import 'package:ngomna_chat/core/constants/app_assets.dart';
import 'package:ngomna_chat/core/constants/app_fonts.dart';

class AuthFormScreen extends StatelessWidget {
  final String title;
  final String inputHint;
  final Function(String) onSubmit;

  const AuthFormScreen({
    super.key,
    required this.title,
    required this.inputHint,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final TextEditingController controller = TextEditingController();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const TopBar(),
            Expanded(
              child: Center(
                child: Container(
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Logo
                      Image.asset(
                        AppAssets.welcomeLogo,
                        width: size.width * 0.35,
                        height: size.height * 0.18,
                        fit: BoxFit.contain,
                      ),

                      // Texte principal
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontFamily: AppFonts.rosarioMedium,
                          height: 1.6,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 4),
                              blurRadius: 8,
                              color: Colors.black38,
                            ),
                          ],
                        ),
                      ),

                      // Champ input
                      Container(
                        width: size.width * 0.7,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.35),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: inputHint,
                            hintStyle: const TextStyle(
                              color: Colors.black38,
                              fontSize: 18,
                              fontFamily: AppFonts.robotoBold,
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          textAlign: TextAlign.center,
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              onSubmit(value);
                            }
                          },
                        ),
                      ),
                    ],
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
