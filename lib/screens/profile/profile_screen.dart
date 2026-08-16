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
  final TextEditingController _passwordController =
      TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

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

  // =========================================================
  // LOAD USER DATA
  // =========================================================

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
  // LOGOUT
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
  // SAVE PROFILE CHANGES
  // =========================================================

  Future<void> _saveChanges(AppLocalizations l10n) async {
    if (_passwordController.text.isNotEmpty &&
        _passwordController.text !=
            _confirmPasswordController.text) {
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

        bool hasLoggedOut = false;

        // =====================================================
        // AUTO LOGOUT DIALOG
        // =====================================================

        showDialog(
          context: context,
          barrierDismissible: false,
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
                    l10n.profileUpdatedAutoLogout,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      l10n.logoutNow,
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

        // =====================================================
        // AUTO LOGOUT AFTER 5 SECONDS
        // =====================================================

        Future.delayed(
          const Duration(seconds: 5),
          () async {
            if (!hasLoggedOut && mounted) {
              hasLoggedOut = true;

              Navigator.of(
                context,
                rootNavigator: true,
              ).pop();

              await _executeLogout();
            }
          },
        );
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // =========================================================
  // LOGOUT CONFIRMATION
  // =========================================================

  Future<void> _handleLogout(
    AppLocalizations l10n,
  ) async {
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
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(
                l10n.cancel,
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
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

  // =========================================================
  // DELETE ACCOUNT
  // =========================================================

  Future<void> _handleDeleteAccount(
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10,
                sigmaY: 10,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _navy.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.redAccent.withOpacity(0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // =================================================
                    // DELETE ICON
                    // =================================================

                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            Colors.redAccent.withOpacity(0.12),
                        border: Border.all(
                          color:
                              Colors.redAccent.withOpacity(0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_forever_outlined,
                        color: Colors.redAccent,
                        size: 38,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =================================================
                    // TITLE
                    // =================================================

                    Text(
                      l10n.deleteAccount,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // =================================================
                    // DESCRIPTION
                    // =================================================

                    Text(
                      l10n.deleteAccountConfirmation,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 25),

                    // =================================================
                    // DELETE BUTTON
                    // =================================================

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            dialogContext,
                            true,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          l10n.deleteAccount,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // =================================================
                    // CANCEL BUTTON
                    // =================================================

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(
                            dialogContext,
                            false,
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: const TextStyle(
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // =====================================================
      // CALL DELETE ACCOUNT API
      // =====================================================

      final success = await AuthService.deleteAccount();

      if (!mounted) return;

      if (success) {
        // ===================================================
        // CLEAR LOCAL DATA
        // ===================================================

        await AuthService.signOut();

        if (!mounted) return;

        // ===================================================
        // SUCCESS MESSAGE
        // ===================================================

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.accountDeletedSuccessfully,
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // ===================================================
        // GO TO AUTH SCREEN
        // ===================================================

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) =>
                const AuthChoiceScreen(),
          ),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.deleteAccountFailed,
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.errorOccurred}$e',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        // =====================================================
        // BACKGROUND
        // =====================================================

        const Positioned.fill(
          child: BackgroundImage(
            imagePath: 'assets/images/bg3.png',
          ),
        ),

        // =====================================================
        // GRADIENT
        // =====================================================

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

        // =====================================================
        // SCAFFOLD
        // =====================================================

        Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: 120,
              ),
              child: Column(
                children: [
                  // =================================================
                  // TOP BAR
                  // =================================================

                  _buildTopBar(),

                  const SizedBox(height: 10),

                  // =================================================
                  // PROFILE HEADER
                  // =================================================

                  _buildHeader(l10n),

                  const SizedBox(height: 30),

                  // =================================================
                  // PROFILE FORM CARD
                  // =================================================

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 1,
                        sigmaY: 1,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _glassBg,
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                Colors.white.withOpacity(.12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // =================================================
                            // NAME
                            // =================================================

                            _buildInputLabel(l10n.name),

                            _buildTextField(
                              controller: _nameController,
                              icon: Icons.person_outline,
                              hint: l10n.enterName,
                            ),

                            const SizedBox(height: 20),

                            // =================================================
                            // EMAIL
                            // =================================================

                            _buildInputLabel(l10n.email),

                            _buildTextField(
                              controller: _emailController,
                              icon: Icons.email_outlined,
                              readOnly: true,
                            ),

                            Padding(
                              padding:
                                  const EdgeInsets.only(
                                top: 6,
                                left: 10,
                                right: 10,
                              ),
                              child: Text(
                                l10n.emailCannotBeChanged,
                                style: TextStyle(
                                  color: Colors.white
                                      .withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // =================================================
                            // NEW PASSWORD
                            // =================================================

                            _buildInputLabel(
                              l10n.newPassword,
                            ),

                            _buildTextField(
                              controller:
                                  _passwordController,
                              icon: Icons.lock_outline,
                              hint: '••••••',
                              isPassword: true,
                            ),

                            Padding(
                              padding:
                                  const EdgeInsets.only(
                                top: 6,
                                left: 10,
                                right: 10,
                              ),
                              child: Text(
                                l10n.leaveBlankKeepCurrent,
                                style: TextStyle(
                                  color: Colors.white
                                      .withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // =================================================
                            // CONFIRM PASSWORD
                            // =================================================

                            _buildInputLabel(
                              l10n.confirmNewPassword,
                            ),

                            _buildTextField(
                              controller:
                                  _confirmPasswordController,
                              icon: Icons.lock_outline,
                              hint:
                                  l10n.confirmNewPasswordHint,
                              isPassword: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // =================================================
                  // ACTION BUTTONS
                  // =================================================

                  Row(
                    children: [
                      // =================================================
                      // CANCEL
                      // =================================================

                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () =>
                                  Navigator.pop(context),
                          style:
                              OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            side: BorderSide(
                              color:
                                  Colors.white.withOpacity(
                                0.3,
                              ),
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
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

                      // =================================================
                      // SAVE
                      // =================================================

                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () =>
                                  _saveChanges(l10n),
                          style:
                              ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            backgroundColor: _accent,
                            foregroundColor: _navy,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _navy,
                                  ),
                                )
                              : Text(
                                  l10n.saveChanges,
                                  style:
                                      const TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // =================================================
                  // LOGOUT BUTTON
                  // =================================================

                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () => _handleLogout(l10n),
                    child: Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent
                            .withOpacity(.12),
                        borderRadius:
                            BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.redAccent
                              .withOpacity(.4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
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
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // =================================================
                  // DELETE ACCOUNT BUTTON
                  // =================================================

                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () =>
                            _handleDeleteAccount(l10n),
                    child: Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red
                            .withOpacity(.06),
                        borderRadius:
                            BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.redAccent
                              .withOpacity(.25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 20,
                          ),

                          const SizedBox(width: 8),

                          Text(
                            l10n.deleteAccount,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w600,
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
  // TOP BAR
  // =========================================================

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
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
              scale: 0.85,
              child: const LanguageSwitcher(),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // PROFILE HEADER
  // =========================================================

  Widget _buildHeader(
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                _accent,
                _accent2,
              ],
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

  // =========================================================
  // INPUT LABEL
  // =========================================================

  Widget _buildInputLabel(
    String label,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
        left: 4,
        right: 4,
      ),
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

  // =========================================================
  // TEXT FIELD
  // =========================================================

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
        borderRadius:
            BorderRadius.circular(12),
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
            color:
                Colors.white.withOpacity(0.3),
          ),
          prefixIcon: Icon(
            icon,
            color: readOnly
                ? Colors.white54
                : _accent,
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
