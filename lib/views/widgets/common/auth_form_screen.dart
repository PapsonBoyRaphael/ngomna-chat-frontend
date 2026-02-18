import 'package:flutter/material.dart';
import 'package:ngomna_chat/views/widgets/common/top_bar.dart';
import 'package:ngomna_chat/views/widgets/common/bottom_nav.dart';
import 'package:ngomna_chat/core/constants/app_assets.dart';
import 'package:ngomna_chat/core/constants/app_fonts.dart';

class AuthFormScreen extends StatefulWidget {
  final String title;
  final String inputHint;
  final Function(String) onSubmit;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final VoidCallback? onCancel;
  final bool showBottomNav;

  const AuthFormScreen({
    super.key,
    required this.title,
    required this.inputHint,
    required this.onSubmit,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.onCancel,
    this.showBottomNav = true,
  });

  @override
  State<AuthFormScreen> createState() => _AuthFormScreenState();
}

class _AuthFormScreenState extends State<AuthFormScreen> {
  late TextEditingController controller;
  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                    mainAxisAlignment: isKeyboardVisible
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.spaceEvenly,
                    children: [
                      if (!isKeyboardVisible) ...[
                        // Logo
                        Image.asset(
                          AppAssets.welcomeLogo,
                          width: size.width * 0.35,
                          height: size.height * 0.18,
                          fit: BoxFit.contain,
                        ),

                        // Texte principal
                        Text(
                          widget.title,
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
                      ],

                      // Groupe Input + Bouton
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          isKeyboardVisible
                              ? const SizedBox(height: 110)
                              : const SizedBox(height: 0),
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
                                  blurRadius: 5,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                hintText: widget.inputHint,
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
                                  widget.onSubmit(value);
                                }
                              },
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Bouton Confirm
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40),
                              ),
                              elevation: 6,
                            ),
                            onPressed: () {
                              final value = controller.text.trim();
                              if (value.isNotEmpty) {
                                widget.onSubmit(value);
                              } else {
                                focusNode.requestFocus();
                              }
                            },
                            child: const Text(
                              'CONFIRM',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                fontFamily: AppFonts.robotoExtraBold,
                                letterSpacing: 1.2,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.showBottomNav)
              const BottomNav()
            else
              const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
