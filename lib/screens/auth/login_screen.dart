import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:naga_app/l10n/app_localizations.dart';

import '../../widgets/shared/language_switcher.dart';
import '../../widgets/onboarding/background_image.dart';
import 'signup_screen.dart';
import '../main/main_navigation_screen.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // 🎨 الألوان الأساسية
  static const Color _navy = Color(0xFF04102A);
  static const Color _accent = Color(0xff19C6FF);
  static const Color _accent2 = Color(0xff29B6F6);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // =========================================================
  // 🚀 LOGIN
  // =========================================================

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // الاتصال بالـ API
      bool isSuccess = await AuthService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      // معرفة لغة التطبيق الحالية
      final isArabic =
          Localizations.localeOf(context).languageCode == 'ar';

      if (isSuccess) {
        // =====================================================
        // ✅ LOGIN SUCCESS
        // =====================================================

        _showCustomPopup(
          isSuccess: true,
          title: isArabic
              ? "تم تسجيل الدخول"
              : "Login Successful",
          message: isArabic
              ? "مرحباً بعودتك! جاري تحويلك للرئيسية..."
              : "Welcome back! Redirecting you to the dashboard...",
          buttonText: isArabic
              ? "متابعة"
              : "Continue",

          // 👇 هنا التعديل المهم
          onPressed: (dialogContext) {
            // قفل الـ Dialog
            Navigator.pop(dialogContext);

            // الانتقال للصفحة الرئيسية
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const MainNavigationScreen(),
              ),
              (route) => false,
            );
          },
        );
      } else {
        // =====================================================
        // ❌ LOGIN FAILED
        // =====================================================

        _showCustomPopup(
          isSuccess: false,
          title: isArabic
              ? "فشل تسجيل الدخول"
              : "Login Failed",
          message: isArabic
              ? "البريد الإلكتروني أو كلمة المرور غير صحيحة."
              : "Your email or password is incorrect.",
          buttonText: isArabic
              ? "حاول مجدداً"
              : "Try Again",

          // 👇 استخدام dialogContext الصحيح
          onPressed: (dialogContext) {
            Navigator.pop(dialogContext);
          },
        );
      }
    } catch (e) {
      debugPrint("Login UI Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // =========================================================
  // 💎 CUSTOM POPUP
  // =========================================================

  void _showCustomPopup({
    required bool isSuccess,
    required String title,
    required String message,
    required String buttonText,

    // 👇 التعديل هنا
    required void Function(BuildContext dialogContext) onPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,

      // 👇 هنا بنستقبل Context الخاص بالـ Dialog
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,

        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),

          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10,
              sigmaY: 10,
            ),

            child: Container(
              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(28),

                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1.5,
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                ],
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),

                  // =================================================
                  // ICON
                  // =================================================

                  Container(
                    width: 75,
                    height: 75,

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,

                      color: isSuccess
                          ? Colors.green.withOpacity(0.2)
                          : Colors.redAccent.withOpacity(0.2),

                      boxShadow: [
                        BoxShadow(
                          color:
                              (isSuccess
                                      ? Colors.green
                                      : Colors.redAccent)
                                  .withOpacity(0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),

                    child: Center(
                      child: Icon(
                        isSuccess
                            ? Icons.check
                            : Icons.close,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =================================================
                  // TITLE
                  // =================================================

                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  // =================================================
                  // MESSAGE
                  // =================================================

                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 28),

                  // =================================================
                  // BUTTON
                  // =================================================

                  Container(
                    width: double.infinity,
                    height: 50,

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),

                      gradient: LinearGradient(
                        colors: isSuccess
                            ? [_accent, _accent2]
                            : [
                                const Color(0xFFFF5E62),
                                const Color(0xFFFF9966),
                              ],
                      ),

                      boxShadow: [
                        BoxShadow(
                          color:
                              (isSuccess
                                      ? _accent
                                      : Colors.redAccent)
                                  .withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),

                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,

                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                      ),

                      // 👇 التعديل المهم هنا
                      onPressed: () => onPressed(dialogContext),

                      child: Text(
                        buttonText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final isArabic =
        Localizations.localeOf(context).languageCode == 'ar';

    return Stack(
      children: [
        // =====================================================
        // BACKGROUND
        // =====================================================

        const BackgroundImage(
          imagePath: 'assets/images/bg3.png',
        ),

        // =====================================================
        // GRADIENT OVERLAY
        // =====================================================

        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,

              colors: [
                _navy.withOpacity(0.65),
                _navy.withOpacity(0.35),
                _navy.withOpacity(0.85),
              ],

              stops: const [
                0.0,
                0.4,
                1.0,
              ],
            ),
          ),
        ),

        // =====================================================
        // SCAFFOLD
        // =====================================================

        Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,

          body: SafeArea(
            child: Column(
              children: [
                // =================================================
                // TOP BAR
                // =================================================

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 25,
                  ),

                  child: Directionality(
                    textDirection: TextDirection.ltr,

                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,

                      crossAxisAlignment:
                          CrossAxisAlignment.start,

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

                

                // =================================================
                // LOGIN FORM
                // =================================================

                Expanded(
                  child: Transform.translate(
                     offset: const Offset(0, -20),
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 2,
                            sigmaY: 2,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.welcomeBack,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: l10n.loginSubtitleHighlight,
                                          style: const TextStyle(
                                            color: _accent,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            height: 1.5,
                                          ),
                                        ),
                                        TextSpan(
                                          text: l10n.loginSubtitleRest,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.85),
                                            fontSize: 14,
                                            fontWeight: FontWeight.normal,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 32),

                                  _buildCustomTextField(
                                    controller: _emailController,
                                    hintText: l10n.email,
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (val) {
                                      return val!.isEmpty
                                          ? (isArabic ? "مطلوب" : "Required")
                                          : null;
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  _buildCustomTextField(
                                    controller: _passwordController,
                                    hintText: l10n.password,
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    obscureText: _obscurePassword,
                                    onTogglePassword: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    validator: (val) {
                                      return val!.isEmpty
                                          ? (isArabic ? "مطلوب" : "Required")
                                          : null;
                                    },
                                  ),

                                  const SizedBox(height: 12),

                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: TextButton(
                                      onPressed: () {},
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        l10n.forgotPassword,
                                        style: const TextStyle(
                                          color: _accent,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 32),

                                  Container(
                                    width: double.infinity,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      gradient: const LinearGradient(
                                        colors: [
                                          _accent,
                                          _accent2,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _accent.withOpacity(0.35),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                      ),
                                      onPressed: _isLoading ? null : _login,
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : Text(
                                              isArabic
                                                  ? "تسجيل الدخول"
                                                  : "Sign In",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const SignupScreen(),
                                          ),
                                        );
                                      },
                                      child: RichText(
                                        text: TextSpan(
                                          text: l10n.dontHaveAccount,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: l10n.createAccountText,
                                              style: const TextStyle(
                                                color: _accent,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // CUSTOM TEXT FIELD
  // =========================================================

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,

    bool isPassword = false,
    bool obscureText = false,

    VoidCallback? onTogglePassword,

    TextInputType keyboardType =
        TextInputType.text,

    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,

      obscureText: obscureText,

      keyboardType: keyboardType,

      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),

      validator: validator,

      decoration: InputDecoration(
        hintText: hintText,

        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.75),
          fontSize: 14,
        ),

        prefixIcon: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),

        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),

                color: Colors.white,

                iconSize: 20,

                onPressed:
                    onTogglePassword,
              )
            : null,

        filled: true,

        fillColor:
            Colors.black.withOpacity(0.2),

        contentPadding:
            const EdgeInsets.symmetric(
          vertical: 18,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),

          borderSide: BorderSide(
            color:
                Colors.white.withOpacity(0.15),
            width: 1,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),

          borderSide:
              const BorderSide(
            color: _accent,
            width: 1.5,
          ),
        ),

        errorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),

          borderSide: BorderSide(
            color:
                Colors.redAccent.withOpacity(0.8),
            width: 1,
          ),
        ),

        focusedErrorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),

          borderSide:
              const BorderSide(
            color: Colors.redAccent,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}