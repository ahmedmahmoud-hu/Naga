import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:naga_app/l10n/app_localizations.dart';

import '../../services/auth_service.dart';
import '../../widgets/onboarding/background_image.dart';
import '../../widgets/shared/language_switcher.dart';

import '../auth/auth_choice_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _navy = Color(0xFF04102A);
  static const Color _accent = Color(0xFF19C6FF);
  static const Color _accent2 = Color(0xFF29B6F6);
  static const Color _glassBg = Color(0x1AFFFFFF);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _username = '';
  String _role = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final data = await AuthService.getLocalUserData();

    if (!mounted) return;

    setState(() {
      _username = data['username'] ?? 'User';
      _role = data['role'] ?? 'user';
      
      _nameController.text = _username;
      _emailController.text = data['email'] ?? 'No Email';
    });
  }

  // =========================================================
  // دالة مساعدة لتنفيذ تسجيل الخروج والانتقال
  // =========================================================
  Future<void> _executeLogout() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const AuthChoiceScreen(),
      ),
      (route) => false,
    );
  }

  // =========================================================
  // حفظ التعديلات وإظهار رسالة النجاح الخاصة
  // =========================================================
  Future<void> _saveChanges(AppLocalizations l10n) async {
    if (_passwordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.passwordsDoNotMatch),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await AuthService.updateProfile(
        name: _nameController.text.trim(),
        newPassword: _passwordController.text.isNotEmpty 
            ? _passwordController.text 
            : null,
      );

      if (!mounted) return;

      if (success) {
        _passwordController.clear();
        _confirmPasswordController.clear();
        setState(() {
          _username = _nameController.text.trim();
        });

        bool hasLoggedOut = false; // لمنع تنفيذ تسجيل الخروج مرتين

        // 1. إظهار الـ Dialog الأصفر مع الترجمة الصحيحة
        showDialog(
          context: context,
          barrierDismissible: false, // يمنع الإغلاق عند الضغط بالخارج
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFFF3CD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.profileUpdatedAutoLogout, // تم استخدام الترجمة هنا بدلاً من النص الثابت
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF856404),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (!hasLoggedOut) {
                        hasLoggedOut = true;
                        Navigator.pop(dialogContext);
                        await _executeLogout();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4299E1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      l10n.logoutNow, // تم استخدام الترجمة للزر أيضاً
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );

        // 2. العداد الزمني (Timer) للتسجيل التلقائي بعد 5 ثوانٍ
        Future.delayed(const Duration(seconds: 5), () async {
          if (!hasLoggedOut && mounted) {
            hasLoggedOut = true;
            Navigator.of(context, rootNavigator: true).pop(); // إغلاق النافذة المنبثقة
            await _executeLogout();
          }
        });

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profileUpdateFailed), 
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.errorOccurred}$e'), 
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // =========================================================
  // تسجيل الخروج العادي (من الزر السفلي)
  // =========================================================
  Future<void> _handleLogout(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _navy,
          title: Text(
            l10n.logout,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            l10n.logoutConfirmation,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                l10n.logout,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _executeLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        // 1. الخلفية الثابتة
        const Positioned.fill(
          child: BackgroundImage(
            imagePath: 'assets/images/bg3.png',
          ),
        ),

        // 2. التدرج اللوني الثابت
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _navy.withOpacity(.85),
                  _navy.withOpacity(.70),
                  _navy.withOpacity(.95),
                ],
              ),
            ),
          ),
        ),

        // 3. الـ Scaffold الشفاف
        Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 120),
              child: Column(
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 10),

                  _buildHeader(l10n),
                  const SizedBox(height: 30),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _glassBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(.12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // NAME FIELD
                            _buildInputLabel(l10n.name),
                            _buildTextField(
                              controller: _nameController,
                              icon: Icons.person_outline,
                              hint: l10n.enterName,
                            ),
                            const SizedBox(height: 20),

                            // EMAIL FIELD (Unchangeable but visible)
                            _buildInputLabel(l10n.email),
                            _buildTextField(
                              controller: _emailController,
                              icon: Icons.email_outlined,
                              readOnly: true,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 6, left: 10, right: 10),
                              child: Text(
                                l10n.emailCannotBeChanged,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // NEW PASSWORD FIELD
                            _buildInputLabel(l10n.newPassword),
                            _buildTextField(
                              controller: _passwordController,
                              icon: Icons.lock_outline,
                              hint: '••••••',
                              isPassword: true,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 6, left: 10, right: 10),
                              child: Text(
                                l10n.leaveBlankKeepCurrent,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // CONFIRM PASSWORD FIELD
                            _buildInputLabel(l10n.confirmNewPassword),
                            _buildTextField(
                              controller: _confirmPasswordController,
                              icon: Icons.lock_outline,
                              hint: l10n.confirmNewPasswordHint,
                              isPassword: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ACTION BUTTONS
                  Row(
                    children: [
                      // CANCEL BUTTON
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            l10n.cancel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // SAVE BUTTON
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _saveChanges(l10n),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: _accent,
                            foregroundColor: _navy,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _navy,
                                  ),
                                )
                              : Text(
                                  l10n.saveChanges,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // LOGOUT BUTTON
                  GestureDetector(
                    onTap: () => _handleLogout(l10n),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(.4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.logout,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.logout,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // HELPER WIDGETS
  // =========================================================

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
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
              scale: 0.85,
              child: const LanguageSwitcher(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_accent, _accent2],
            ),
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity(.35),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 45,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          _username,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          l10n.manageAccount,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    bool isPassword = false,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: readOnly 
            ? Colors.white.withOpacity(0.05) 
            : Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: readOnly 
              ? Colors.transparent 
              : Colors.white.withOpacity(0.15),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        readOnly: readOnly,
        style: const TextStyle(
          color: Colors.white, 
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.3),
          ),
          prefixIcon: Icon(
            icon,
            color: readOnly ? Colors.white54 : _accent,
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}