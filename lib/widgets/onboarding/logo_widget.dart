import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle, // بيفترض إن اللوجو دائري أو مربع، بيظبط الـ Glow
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.2), // توهج أبيض خفيف
            blurRadius: 40, // تشتيت عالي عشان يبان طبيعي ومش حاد
            spreadRadius: 2,
          ),
        ],
      ),
      child: Image.asset(
        "assets/images/logo.png",
        width: width * 0.22, // الحجم المتناسق مع باقي الشاشة
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}