import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:naga_app/l10n/app_localizations.dart';

import '../../widgets/shared/language_switcher.dart';
import '../../widgets/onboarding/background_image.dart';
import 'login_screen.dart'; 
import '../../services/auth_service.dart'; // 🚀 استدعاء ملف الـ API

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers لجميع الحقول
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // 🎨 الألوان الأساسية
  static const Color _navy = Color(0xFF04102A);
  static const Color _accent = Color(0xff19C6FF);
  static const Color _accent2 = Color(0xff29B6F6);

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// =========================================
  /// 🚀 دالة إنشاء الحساب المربوطة بالـ API
  /// =========================================
  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // دمج الاسم الأول والأخير مع مسافة بينهم
      String username = "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}";

      // الاتصال بالـ API
      bool isSuccess = await AuthService.signUp(
        username,
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      // معرفة لغة التطبيق الحالية
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';

      if (isSuccess) {
        // 🚀 إظهار Pop-up النجاح
        _showCustomPopup(
          isSuccess: true,
          title: isArabic ? "تم إنشاء الحساب" : "Account Created",
          message: isArabic ? "تم إنشاء الحساب بنجاح! برجاء تسجيل الدخول." : "Account created successfully! Please sign in.",
          buttonText: isArabic ? "متابعة" : "Continue",
          onPressed: () {
            Navigator.pop(context); // قفل الديالوج
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        );
      } else {
        // 🚀 إظهار Pop-up الفشل
        _showCustomPopup(
          isSuccess: false,
          title: isArabic ? "فشل إنشاء الحساب" : "Creation Failed",
          message: isArabic ? "البريد الإلكتروني أو كلمة المرور غير صحيحة." : "Your email or password is incorrect.",
          buttonText: isArabic ? "حاول مجدداً" : "Try Again",
          onPressed: () => Navigator.pop(context), // قفل الديالوج فقط لإعادة المحاولة
        );
      }
    } catch (e) {
      debugPrint("Signup UI Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// =========================================
  /// 💎 دالة عرض الـ Pop-up الزجاجي المخصص
  /// =========================================
  void _showCustomPopup({
    required bool isSuccess,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
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
                  // أيقونة النجاح أو الفشل
                  Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSuccess ? Colors.green.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: (isSuccess ? Colors.green : Colors.redAccent).withOpacity(0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        isSuccess ? Icons.check : Icons.close,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // العنوان
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
                  // الرسالة
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
                  // زر المتابعة / المحاولة
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: isSuccess 
                            ? [_accent, _accent2] 
                            : [const Color(0xFFFF5E62), const Color(0xFFFF9966)], // تدرج أحمر للفشل زي الصورة
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isSuccess ? _accent : Colors.redAccent).withOpacity(0.4),
                          blurRadius: 12,
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
                      onPressed: onPressed,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Stack(
      children: [
        /// 1. صورة الخلفية (ثابتة)
        const BackgroundImage(imagePath: 'assets/images/bg3.png'),

        /// 2. تدرج لوني 
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
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),

        /// 3. الـ Scaffold
        Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                /// -----------------------------------
                /// Top Bar
                /// -----------------------------------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, 0),
                          child: Image.asset('assets/images/kasct.png', height: 35),
                        ),
                        Transform.scale(
                          scale: 0.90,
                          child: const LanguageSwitcher(),
                        ),
                      ],
                    ),
                  ),
                ),

                /// -----------------------------------
                /// Signup Form (Frosted Glass Card)
                /// -----------------------------------
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), 
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
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
                                    l10n.createAccountTitle, 
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 0),
                                  
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: l10n.createAccountSubtitleHighlight, 
                                          style: const TextStyle(
                                            color: _accent,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800, 
                                            height: 1.5,
                                          ),
                                        ),
                                        TextSpan(
                                          text: l10n.createAccountSubtitleRest, 
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

                                  // First Name & Last Name
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildCustomTextField(
                                          controller: _firstNameController,
                                          hintText: l10n.firstName,
                                          icon: Icons.person_outline,
                                          validator: (val) => val!.isEmpty ? (isArabic ? "مطلوب" : "Required") : null,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _buildCustomTextField(
                                          controller: _lastNameController,
                                          hintText: l10n.lastName,
                                          icon: Icons.person_outline,
                                          validator: (val) => val!.isEmpty ? (isArabic ? "مطلوب" : "Required") : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Email Field
                                  _buildCustomTextField(
                                    controller: _emailController,
                                    hintText: l10n.email,
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (val) => val!.isEmpty ? (isArabic ? "مطلوب" : "Required") : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // Password Field
                                  _buildCustomTextField(
                                    controller: _passwordController,
                                    hintText: l10n.password,
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    obscureText: _obscurePassword,
                                    onTogglePassword: () {
                                      setState(() => _obscurePassword = !_obscurePassword);
                                    },
                                    validator: (val) => val!.isEmpty ? (isArabic ? "مطلوب" : "Required") : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // Confirm Password Field
                                  _buildCustomTextField(
                                    controller: _confirmPasswordController,
                                    hintText: l10n.confirmPassword,
                                    icon: Icons.lock_reset_outlined,
                                    isPassword: true,
                                    obscureText: _obscureConfirmPassword,
                                    onTogglePassword: () {
                                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                    },
                                    validator: (val) {
                                      if (val == null || val.isEmpty) return isArabic ? "مطلوب" : "Required";
                                      if (val != _passwordController.text) return isArabic ? "غير متطابق" : "Not matched";
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 32),

                                  // Sign Up Button
                                  Container(
                                    width: double.infinity,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      gradient: const LinearGradient(
                                        colors: [_accent, _accent2],
                                      ),
                                      boxShadow: [
                                        BoxShadow(color: _accent.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 8)),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                      ),
                                      onPressed: _isLoading ? null : _signup,
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                            )
                                          : Text(
                                              l10n.createAccountTitle, 
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

                                  // Back to Login Route
                                  Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const LoginScreen(),
                                          ),
                                        );
                                      },
                                      child: RichText(
                                        text: TextSpan(
                                          text: l10n.alreadyHaveAccount, 
                                          style: const TextStyle(color: Colors.white, fontSize: 14),
                                          children: [
                                            TextSpan(
                                              text: l10n.signIn, 
                                              style: const TextStyle(color: _accent, fontWeight: FontWeight.bold),
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// =========================================
  /// Custom TextField (High Contrast Field)
  /// =========================================
  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13), 
        prefixIcon: Icon(icon, color: Colors.white, size: 20), 
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                color: Colors.white, 
                iconSize: 20,
                onPressed: onTogglePassword,
              )
            : null,
        filled: true,
        fillColor: Colors.black.withOpacity(0.2), 
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.8), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}
