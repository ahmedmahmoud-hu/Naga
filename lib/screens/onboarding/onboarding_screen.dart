import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:naga_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart'; // تمت إضافة الحزمة هنا

import '../../widgets/onboarding/background_image.dart';
import '../../widgets/onboarding/logo_widget.dart';
import '../../widgets/onboarding/title_section.dart';
import '../../widgets/shared/language_switcher.dart';

import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  /// --- PageView Controller ---
  late PageController _pageController;
  int _currentPage = 0;

  /// --- Video Controller ---
  late VideoPlayerController _videoController;

  // Animation Controller for the "Pulse" effect on Next button
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  /// 🚀 قائمة الخلفيات 
  final List<String> _bgImages = [
    'assets/images/bg1.png', 
    'assets/images/bg2.png',  
    'assets/images/bg3.png',  
  ];

  @override
  void initState() {
    super.initState();

    // viewportFraction = 1.0 (الافتراضي) عشان كل صفحة تاخد العرض كامل
    // ونضيف Listener عشان نحدّث الـ Transform/Opacity مع كل حركة سحب
    _pageController = PageController(initialPage: 0);
    _pageController.addListener(() {
      setState(() {});
    });

    /// Setup Pulse Animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    /// Setup Video
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse("http://91.108.112.27:5021/videos/SmartVisualPollution.mp4"),
    );

    _videoController.initialize().then((_) async {
      await _videoController.setLooping(true);
      await _videoController.setVolume(1.0);
      await _videoController.play();
      if (mounted) setState(() {});
    }).catchError((e) {
      debugPrint("Video Error: $e");
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  void _playPause() {
    if (_videoController.value.isPlaying) {
      _videoController.pause();
    } else {
      _videoController.play();
    }
    setState(() {});
  }

  void _onNextPressed() {
    if (_currentPage < 2) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  /// -------------------------------------------------------------
  /// دالة لحفظ حالة الـ Onboarding والانتقال للصفحة التالية
  /// -------------------------------------------------------------
  Future<void> _completeOnboarding(Widget nextScreen) async {
    final prefs = await SharedPreferences.getInstance();
    // بنحفظ إن المستخدم شاف الـ Onboarding والـ Welcome
    await prefs.setBool('hasSeenOnboarding', true); 
    
    if (!mounted) return;
    
    // بنستخدم pushReplacement عشان المستخدم ميقدرش يرجع للصفحة دي بـ زرار الـ Back
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        body: Stack(
          children: [
            /// 1. Dynamic Background Image 
            BackgroundImage(imagePath: _bgImages[_currentPage]),

            /// 2. Premium Gradient Overlay (Navy Blue) + Soft Blur (0.4) 
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0.4, sigmaY: 0.4), 
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF04102A).withOpacity(0.9),  
                      const Color(0xFF04102A).withOpacity(0.15), 
                      const Color(0xFF04102A).withOpacity(0.95), 
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    /// -----------------------------------
                    /// Top Bar (KACST Logo + Language)
                    /// -----------------------------------
                    Row(
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
                          scale: 0.95, 
                          child: const LanguageSwitcher(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    /// -----------------------------------
                    /// PageView (محتوى الصفحات المتغير)
                    /// -----------------------------------
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });

                          if (index != 0) {
                            _videoController.pause();
                          }
                        },
                        itemCount: 3,
                        itemBuilder: (context, index) {
                          Widget page;
                          if (index == 0) {
                            page = _buildVideoPage(l10n);
                          } else if (index == 1) {
                            page = _buildStepsPage(context, l10n);
                          } else {
                            page = _buildPlaceholderPage(l10n);
                          }
                          return _buildTransitionWrapper(index: index, child: page);
                        },
                      ),
                    ),

                    const SizedBox(height: 20), 

                    /// -----------------------------------
                    /// Onboarding Dots (ثابتة في كل الصفحات)
                    /// -----------------------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      textDirection: TextDirection.ltr,
                      children: [
                        _buildDot(index: 0),
                        const SizedBox(width: 6),
                        _buildDot(index: 1),
                        const SizedBox(width: 6),
                        _buildDot(index: 2),
                      ],
                    ),
                    
                    const SizedBox(height: 24),

                    /// -----------------------------------
                    /// Dynamic Bottom Section (تغيير الزراير)
                    /// -----------------------------------
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: _currentPage < 2 
                          ? _buildNextAndSkipSection(l10n) 
                          : _buildAuthButtonsSection(l10n),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// =========================================
  /// Slide + Fade Transition Wrapper (احترافي)
  /// =========================================
  Widget _buildTransitionWrapper({required int index, required Widget child}) {
    double page = _currentPage.toDouble();
    if (_pageController.position.haveDimensions) {
      page = _pageController.page ?? _currentPage.toDouble();
    }

    final double value = (page - index);
    final double clamped = value.clamp(-1.0, 1.0);
    final double opacity = (1 - clamped.abs()).clamp(0.0, 1.0);
    final double dx = clamped * 60;
    final double scale = (1 - (clamped.abs() * 0.08)).clamp(0.85, 1.0);

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: Transform.scale(
          scale: scale,
          child: child,
        ),
      ),
    );
  }

  /// =========================================
  /// Bottom Section 1: Next & Skip (Pages 1 & 2)
  /// =========================================
  Widget _buildNextAndSkipSection(AppLocalizations l10n) {
    return Column(
      key: const ValueKey('next_skip_section'),
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: double.infinity,
            height: 52, 
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xff19C6FF), 
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff19C6FF).withOpacity(0.35), 
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _onNextPressed,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.next, 
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded, 
                    color: Colors.white, 
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8),

        Center(
          child: TextButton(
            // 🚀 التعديل هنا: ربط زرار التخطي بالدالة والانتقال لشاشة الدخول
            onPressed: () => _completeOnboarding(const LoginScreen()), 
            style: TextButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.skip,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85), 
                fontSize: 15, 
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12), 
      ],
    );
  }

  /// =========================================
  /// Bottom Section 2: Auth Buttons (Page 3) 🚀
  /// =========================================
  Widget _buildAuthButtonsSection(AppLocalizations l10n) {
    return Column(
      key: const ValueKey('auth_buttons_section'),
      children: [
        // 1. Create Account Button
        Container(
          width: double.infinity,
          height: 52, 
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xff19C6FF), 
            boxShadow: [
              BoxShadow(
                color: const Color(0xff19C6FF).withOpacity(0.35), 
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            // 🚀 التعديل هنا: حفظ حالة Onboarding والانتقال لإنشاء حساب
            onPressed: () => _completeOnboarding(const SignupScreen()),
            icon: const Icon(Icons.person, color: Colors.white, size: 22),
            label: Text(
              l10n.createAccount, 
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),

        // 2. Sign In Button
        SizedBox(
          width: double.infinity,
          height: 52, 
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            // 🚀 التعديل هنا: حفظ حالة Onboarding والانتقال لتسجيل الدخول
            onPressed: () => _completeOnboarding(const LoginScreen()),
            icon: const Icon(Icons.login, color: Colors.white, size: 20),
            label: Text(
              l10n.signIn, 
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// =========================================
  /// Page 1: Video Page
  /// =========================================
  Widget _buildVideoPage(AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const LogoWidget(),
        const SizedBox(height: 12),

        TitleSection(
          title: l10n.onboarding1Title,
          description: l10n.onboarding1Description,
        ),
        const SizedBox(height: 24), 
        _buildVideoCard(),
      ],
    );
  }

  /// =========================================
  /// Page 2: How It Works 
  /// =========================================
  Widget _buildStepsPage(BuildContext context, AppLocalizations l10n) {
    final availableWidth = MediaQuery.of(context).size.width - 48;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TitleSection(
          title: l10n.onboarding2Title,
          description: l10n.onboarding2Description,
        ),
        const SizedBox(height: 24),
        
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: availableWidth, 
              child: Column(
                children: [
                  _buildStepCard(
                    context, 
                    number: "1",
                    icon: Icons.camera_alt_outlined,
                    title: l10n.step1Title,
                    description: l10n.step1Desc,
                  ),
                  _buildStepCard(
                    context, 
                    number: "2",
                    icon: Icons.psychology_outlined,
                    title: l10n.step2Title,
                    description: l10n.step2Desc,
                  ),
                  _buildStepCard(
                    context, 
                    number: "3",
                    icon: Icons.send_rounded,
                    title: l10n.step3Title,
                    description: l10n.step3Desc,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// =========================================
  /// Page 3: Placeholder 
  /// =========================================
  Widget _buildPlaceholderPage(AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/logo3.png', 
          height: 140, 
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 0), 
        TitleSection(
          title: l10n.onboarding3Title,
          description: l10n.onboarding3Description,
        ),
      ],
    );
  }

  /// =========================================
  /// Step Card Widget (RTL ONLY inside this card)
  /// =========================================
  Widget _buildStepCard(BuildContext context, {required String number, required IconData icon, required String title, required String description}) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final cardDirection = isArabic ? TextDirection.rtl : TextDirection.ltr;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Directionality(
        textDirection: cardDirection,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsetsDirectional.only(top: 8, start: 8), 
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18), 
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04), 
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.02),
                      border: Border.all(color: const Color(0xff19C6FF).withOpacity(0.5), width: 1.5),
                    ),
                    child: Icon(icon, color: Colors.white, size: 26), 
                  ),
                  const SizedBox(width: 16), 
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13.5, 
                            height: 1.4, 
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            PositionedDirectional(
              top: 0,
              start: 0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xff19C6FF), 
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff19C6FF).withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// =========================================
  /// Video Card Widget
  /// =========================================
  Widget _buildVideoCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack, 
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width * .78, 
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.15), 
                width: 0.5, 
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15), 
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: GestureDetector(
                  onTap: _videoController.value.isInitialized ? _playPause : null,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/video_poster.png',
                        fit: BoxFit.cover,
                      ),

                      if (_videoController.value.isInitialized) ...[
                        FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _videoController.value.size.width,
                            height: _videoController.value.size.height,
                            child: VideoPlayer(_videoController),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(.0),
                                Colors.black.withOpacity(.3),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14, right: 14, bottom: 24,
                          child: ValueListenableBuilder(
                            valueListenable: _videoController,
                            builder: (context, VideoPlayerValue value, child) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDuration(value.position), style: _timeStyle()),
                                  Text(_formatDuration(value.duration), style: _timeStyle()),
                                ],
                              );
                            },
                          ),
                        ),
                        Positioned(
                          left: 12, right: 12, bottom: 8,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: VideoProgressIndicator(
                              _videoController,
                              allowScrubbing: true,
                              padding: EdgeInsets.zero,
                              colors: const VideoProgressColors(
                                playedColor: Color(0xff19C6FF), 
                                bufferedColor: Colors.white24,
                                backgroundColor: Colors.white10,
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 250),
                            opacity: _videoController.value.isPlaying ? 0 : 1,
                            child: Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(.4), 
                                border: Border.all(color: Colors.white.withOpacity(.5)),
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          color: Colors.black.withOpacity(0.3),
                          child: const Center(
                            child: CircularProgressIndicator(color: Color(0xff19C6FF)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// =========================================
  /// Helper Methods
  /// =========================================
  TextStyle _timeStyle() => const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600);

  Widget _buildDot({required int index}) {
    bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 6,
      width: isActive ? 20 : 6,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xff19C6FF) : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}