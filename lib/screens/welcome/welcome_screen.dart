import 'package:flutter/material.dart';
import 'package:naga_app/l10n/app_localizations.dart';

import '../onboarding/onboarding_screen.dart';
import '../../widgets/shared/language_switcher.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [

          ///==========================
          /// Background
          ///==========================
          
          Image.asset(
            "assets/images/welcome.png",
            fit: BoxFit.cover,
          ),

          ///==========================
          /// Dark Overlay
          ///==========================
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x15000000),
                  Color(0x55000000),
                  Color(0xCC000000),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [

                  ///==========================
                  /// Top Bar (Fixed LTR)
                  ///==========================
                  const SizedBox(height: 20), 
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, 0), 
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.18), 
                                  blurRadius: 40,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/kasct.png',
                              height: 35,
                            ),
                          ),
                        ),
                        
                        Transform.scale(
                          scale: 0.90, 
                          child: const LanguageSwitcher(),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  ///==========================
                  /// Title (Dynamic RTL/LTR)
                  ///==========================
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          colors: [
                            Color(0xff19C6FF),
                            Color(0xff9BE7FF),
                          ],
                        ).createShader(bounds);
                      },
                      child: Text(
                        l10n.welcomeTitle,
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          height: 1.05,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 2),

                  ///==========================
                  /// Subtitle (Dynamic RTL/LTR)
                  ///==========================
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      l10n.welcomeSubtitle,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  
                  ///==========================
                  /// Get Started Button (Fixed LTR)
                  ///==========================
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              transitionDuration: const Duration(milliseconds: 600),
                              pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                const begin = Offset(0.05, 0.0); // مسافة سحب بسيطة
                                const end = Offset.zero;
                                const curve = Curves.easeInOutCubic;

                                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff19C6FF),
                          foregroundColor: Colors.white,
                          elevation: 18,
                          shadowColor: const Color(0xff19C6FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.getStarted,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}