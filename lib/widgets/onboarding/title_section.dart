import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class TitleSection extends StatelessWidget {
  final String title;
  final String description;

  const TitleSection({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// Title (NAGA)
        ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [AppColors.primaryLight, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white, 
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5, // 🚀 Letter Spacing لكلمة NAGA
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.4), // 🚀 Shadow خفيف لتبدو أفخم
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        /// Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85), 
              fontSize: 14.5, // 🚀 تصغير الخط نقطة بسيطة
              height: 1.35,   // 🚀 تقليل المسافة بين السطرين
              fontWeight: FontWeight.w400,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}