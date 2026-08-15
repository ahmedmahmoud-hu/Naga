import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/language_controller.dart';

class LanguageSwitcher extends StatefulWidget {
  const LanguageSwitcher({super.key});

  @override
  State<LanguageSwitcher> createState() => _LanguageSwitcherState();
}

class _LanguageSwitcherState extends State<LanguageSwitcher> {
  bool _playShimmer = false;

  void _changeLanguage(bool isEnglish) async {
    HapticFeedback.selectionClick();

    setState(() {
      _playShimmer = true;
    });

    languageController.changeLanguage(
      isEnglish ? "ar" : "en",
    );

    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    if (mounted) {
      setState(() {
        _playShimmer = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageController,
      builder: (context, _) {
        final isEnglish =
            languageController.locale.languageCode == "en";

        final screenWidth = MediaQuery.of(context).size.width;

        // صغرنا العرض والارتفاع عشان يبان أصغر وأنيق
        final switchWidth =
            (screenWidth * .25).clamp(85.0, 105.0);

        final switchHeight =
            (screenWidth * .10).clamp(34.0, 40.0);

        final sliderWidth = switchWidth / 2 - 4;
        final sliderHeight = switchHeight - 4;

        final fontSize =
            (screenWidth * .032).clamp(11.0, 13.0);

        return GestureDetector(
          onTap: () => _changeLanguage(isEnglish),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(switchHeight),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 12,
                sigmaY: 12,
              ),
              child: Container(
                width: switchWidth,
                height: switchHeight,
                padding: const EdgeInsets.all(2), // قللناها من 3 لـ 2 عشان الـ Padding الداخلي يقل
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.08),
                  borderRadius:
                      BorderRadius.circular(switchHeight),
                  border: Border.all(
                    color: Colors.white.withOpacity(.15),
                  ),
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration:
                          const Duration(milliseconds: 450),
                      curve:
                          Curves.fastEaseInToSlowEaseOut,
                      alignment: isEnglish
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Stack(
                        children: [
                          Container(
                            width: sliderWidth,
                            height: sliderHeight,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(
                                      sliderHeight),
                              gradient:
                                  const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xff7EF9FF),
                                  Color(0xff37B9F1),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xff37B9F1)
                                          .withOpacity(.4),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),

                          if (_playShimmer)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(
                                        sliderHeight),
                                child: TweenAnimationBuilder<
                                    double>(
                                  tween: Tween(
                                    begin: -1,
                                    end: 2,
                                  ),
                                  duration: const Duration(
                                      milliseconds: 650),
                                  builder:
                                      (context, value, _) {
                                    return Transform.translate(
                                      offset: Offset(
                                        value *
                                            sliderWidth,
                                        0,
                                      ),
                                      child: Container(
                                        width: 14,
                                        decoration:
                                            BoxDecoration(
                                          gradient:
                                              LinearGradient(
                                            colors: [
                                              Colors
                                                  .transparent,
                                              Colors.white
                                                  .withOpacity(
                                                      .6),
                                              Colors
                                                  .transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: Center(
                            child:
                                AnimatedDefaultTextStyle(
                              duration:
                                  const Duration(
                                      milliseconds: 250),
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight:
                                    FontWeight.w700,
                                color: isEnglish
                                    ? Colors.black
                                    : Colors.white,
                              ),
                              child:
                                  const Text("EN"),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child:
                                AnimatedDefaultTextStyle(
                              duration:
                                  const Duration(
                                      milliseconds: 250),
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight:
                                    FontWeight.w700,
                                color: isEnglish
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              child:
                                  const Text("AR"),
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
        );
      },
    );
  }
}