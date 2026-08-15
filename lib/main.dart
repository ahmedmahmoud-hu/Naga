import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:naga_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 🚀 استدعاء مكتبة dotenv

import 'controllers/language_controller.dart';
import 'screens/welcome/welcome_screen.dart';
import 'theme/app_theme.dart';

import 'screens/auth/auth_choice_screen.dart';
import 'screens/home/home_screen.dart'; // 🚀 1. استدعاء الصفحة الرئيسية
import 'screens/main/main_navigation_screen.dart';
// 🚀 RouteObserver عشان الشاشات تعرف لما ترجع تظهر تاني (زي HomeScreen)
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تحميل ملف الـ .env قبل تشغيل أي حاجة في التطبيق
  await dotenv.load(fileName: ".env");

  // تحميل اللغة المحفوظة
  await languageController.loadSavedLanguage();

  // جلب البيانات من الذاكرة
  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false; // 🚀 2. جلب حالة تسجيل الدخول

  // تمرير القيمتين لـ MyApp
  runApp(MyApp(
    hasSeenOnboarding: hasSeenOnboarding,
    isLoggedIn: isLoggedIn, // 🚀 تمريرها هنا
  ));
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding; 
  final bool isLoggedIn; // 🚀 3. تعريف المتغير

  const MyApp({
    super.key, 
    required this.hasSeenOnboarding,
    required this.isLoggedIn, // 🚀 إضافته هنا
  }); 

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageController,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "NAGA",

          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,

          locale: languageController.locale,

          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,

          // 🚀 تسجيل الـ RouteObserver عشان الشاشات تقدر تعمل subscribe
          navigatorObservers: [routeObserver],

          // 🚀 4. التعديل الذكي للـ Routing
          home: isLoggedIn 
              ? const MainNavigationScreen() // لو مسجل دخول يروح للرئيسية
              : (hasSeenOnboarding 
                  ? const AuthChoiceScreen() // لو مش مسجل بس شاف الترحيب
                  : const WelcomeScreen()), // لو أول مرة يفتح التطبيق
        );
      },
    );
  }
}