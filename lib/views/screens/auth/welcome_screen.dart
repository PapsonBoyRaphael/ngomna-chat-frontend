import 'package:flutter/material.dart';
import 'package:ngomna_chat/views/screens/auth/enter_matricule_screen.dart';
import 'package:ngomna_chat/views/widgets/common/top_bar.dart';
import 'package:ngomna_chat/views/widgets/common/bottom_nav.dart';
import 'package:ngomna_chat/core/routes/app_routes.dart';
import 'package:ngomna_chat/core/constants/app_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
                      Image.asset(
                        'assets/icons/welcome_logo.png',
                        width: size.width * 0.37,
                        height: size.height * 0.18,
                        fit: BoxFit.contain,
                      ),
                      const Text(
                        'WELCOME TO\nNGOMNA\nINSTANT CHAT !!!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFonts.rosarioMedium,
                          height: 1.6,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 4),
                              blurRadius: 8,
                              color: Colors.black38,
                            )
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 26,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 6,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(
                              context, AppRoutes.enterMatricule);
                        },
                        child: const Text(
                          'GET STARTED',
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
