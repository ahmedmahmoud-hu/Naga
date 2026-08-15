import 'package:flutter/material.dart';

class GradientOverlay extends StatelessWidget {
  const GradientOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// Blue Tint (أخف)
        Container(
          color: const Color(0xFF041A2D).withOpacity(.15),
        ),

        /// Main Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [
                0.0,
                .45,
                .80,
                1.0,
              ],
              colors: [
                Color(0x0500D4FF),
                Color(0x1500BFFF),
                Color(0x5503182A),
                Color(0xCC020B14),
              ],
            ),
          ),
        ),

        /// Bottom Fade
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 260,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x55020F19),
                  Color(0xB0020912),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}