import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:naga_app/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart'; 

import '../../widgets/shared/language_switcher.dart';
import '../../widgets/onboarding/background_image.dart';
import '../../widgets/onboarding/logo_widget.dart'; 
import '../../widgets/onboarding/title_section.dart'; 

import 'login_screen.dart';
import 'signup_screen.dart';

class AuthChoiceScreen extends StatefulWidget {
  const AuthChoiceScreen({super.key});

  @override
  State<AuthChoiceScreen> createState() => _AuthChoiceScreenState();
}

class _AuthChoiceScreenState extends State<AuthChoiceScreen> with SingleTickerProviderStateMixin {
  // 🎨 الألوان الأساسية
  static const Color _navy = Color(0xFF04102A);
  static const Color _accent = Color(0xff19C6FF);
  static const Color _accentDark = Color(0xff0F85FF);

  /// --- Video Controller ---
  late VideoPlayerController _videoController;

  /// --- Animations & Scroll ---
  late AnimationController _arrowController;
  late Animation<double> _arrowFadeAnimation;
  late Animation<double> _arrowSlideAnimation;
  
  // 🚀 متحكم السكرول والمتغير اللي بيحدد ظهور السهم
  late ScrollController _scrollController;
  bool _isArrowVisible = true;

  @override
  void initState() {
    super.initState();
    
    // 🚀 مراقبة حركة الشاشة (Scroll Listener)
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      // لو نزل أكتر من 20 بيكسل، السهم يختفي
      if (_scrollController.offset > 20 && _isArrowVisible) {
        setState(() => _isArrowVisible = false);
      } 
      // لو رجع لأول الشاشة، السهم يظهر تاني
      else if (_scrollController.offset <= 20 && !_isArrowVisible) {
        setState(() => _isArrowVisible = true);
      }
    });

    // 🚀 تهيئة أنيميشن السهم
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), 
    )..repeat(reverse: true); 

    _arrowFadeAnimation = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );
    _arrowSlideAnimation = Tween<double>(begin: -4.0, end: 6.0).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );

    // 🚀 تهيئة مشغل الفيديو
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
    _scrollController.dispose(); // 🧹 تنظيف متحكم السكرول
    _arrowController.dispose(); 
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

  // 🚀 دالة الانتقال المحدثة بالكامل
  void _navigateTo(Widget screen) {
    // 1. حفظ حالة الفيديو (هل كان شغال ولا المستخدم وقفه بإيده؟)
    final bool wasPlaying = _videoController.value.isPlaying;

    // 2. لو شغال نوقفه مؤقتاً عشان ميسحبش موارد في الخلفية
    if (wasPlaying) {
      _videoController.pause();
      setState(() {}); 
    }

    // 3. ننتقل للصفحة التانية
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((_) {
      // 4. الكود هنا هيتنفذ لما المستخدم يعمل "رجوع" للشاشة دي:
      
      // 👈 نرجع السكرول لأول الصفحة فوق خالص بلمح البصر
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
      }

      // 👈 نرجع نشغل الفيديو *فقط* لو كان شغال قبل ما نروح
      if (mounted && wasPlaying) {
        _videoController.play();
        setState(() {});
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  TextStyle _timeStyle() => const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: _navy,
      body: Stack(
        children: [
          /// 1. صورة الخلفية
          const BackgroundImage(imagePath: 'assets/images/bg3.png'),

          /// 2. تدرج لوني غامق
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _navy.withOpacity(0.7),
                  _navy.withOpacity(0.5),
                  _navy.withOpacity(0.9),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                /// -----------------------------------
                /// Top Bar
                /// -----------------------------------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 25),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Image.asset(
                            'assets/images/kasct.png',
                            height: 35,
                          ),
                          Transform.scale(
                            scale: 0.90,
                            child: const LanguageSwitcher(),
                          ),
                        ],
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController, 
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        /// -----------------------------------
                        /// NAGA Logo & Title
                        /// -----------------------------------
                        const LogoWidget(),
                        const SizedBox(height: 15),
                        TitleSection(
                          title: l10n.nagaTitle,
                          description: l10n.nagaSubtitle,
                        ),
                        const SizedBox(height: 32),

                        /// -----------------------------------
                        /// Video Player
                        /// -----------------------------------
                        Container(
                          height: 180, 
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _accent.withOpacity(0.5), width: 1.5),
                            color: Colors.black.withOpacity(0.3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: GestureDetector(
                              onTap: _videoController.value.isInitialized ? _playPause : null,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
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
                                            Colors.black.withOpacity(.4),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 14, right: 14, bottom: 22,
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
                                            playedColor: _accent, 
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
                                    const Center(
                                      child: CircularProgressIndicator(color: _accent),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        /// -----------------------------------
                        /// Slogan
                        /// -----------------------------------
                        Text(
                          l10n.togetherTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _accent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.togetherSubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        
                        const SizedBox(height: 12),

                        /// -----------------------------------
                        /// 🚀 السهم التفاعلي 
                        /// -----------------------------------
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300), 
                          opacity: _isArrowVisible ? 1.0 : 0.0,
                          child: AnimatedBuilder(
                            animation: _arrowController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _arrowFadeAnimation.value,
                                child: Transform.translate(
                                  offset: Offset(0, _arrowSlideAnimation.value),
                                  child: child,
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.keyboard_double_arrow_down_rounded, 
                              color: _accent,
                              size: 28,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        /// -----------------------------------
                        /// Sign In Button
                        /// -----------------------------------
                        Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [_accentDark, _accent],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            // 🚀 استخدام الدالة المحدثة
                            onPressed: () => _navigateTo(const LoginScreen()),
                            icon: const Icon(Icons.person_outline, color: Colors.white),
                            label: Text(
                              l10n.signIn,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        /// -----------------------------------
                        /// OR Divider
                        /// -----------------------------------
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.white.withOpacity(0.2), thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                l10n.or,
                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.white.withOpacity(0.2), thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        /// -----------------------------------
                        /// Create Account Button
                        /// -----------------------------------
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _accentDark, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              backgroundColor: Colors.transparent,
                            ),
                            // 🚀 استخدام الدالة المحدثة
                            onPressed: () => _navigateTo(const SignupScreen()),
                            icon: const Icon(Icons.person_add_alt_1_outlined, color: _accent),
                            label: Text(
                              l10n.createAccountTitle,
                              style: const TextStyle(color: _accent, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}