import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 🚀 لاستدعاء الرابط من .env

class AuthService {
  // 🚀 سحب الرابط الأساسي من ملف الـ .env 
  // القيمة هنا هتكون: http://10.0.2.2:5021/api
  static final String baseUrl = dotenv.env['API_BASE_URL'] ?? "http://10.0.2.2:5021/api";

  /// ========================================
  /// 1. دالة تسجيل الدخول (Sign In)
  /// ========================================
  static Future<bool> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/login'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Email': email,
          'Password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          
          // سحب الـ Cookie من سيرفر C# وحفظها في الموبايل
          String? rawCookie = response.headers['set-cookie'];
          if (rawCookie != null) {
            await prefs.setString('jwt_cookie', rawCookie);
          }

          // حفظ بيانات المستخدم في الذاكرة المحلية
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('username', data['username'] ?? '');
          await prefs.setString('role', data['role'] ?? '');
          await prefs.setString('email', email); // 🚀 حفظ الإيميل لاستخدامه في صفحة البروفايل
          
          return true;
        }
      }
      return false; // فشل تسجيل الدخول
    } catch (e) {
      debugPrint("SignIn Error: $e");
      return false;
    }
  }

  /// ========================================
  /// 2. دالة إنشاء حساب جديد (Sign Up)
  /// ========================================
  static Future<bool> signUp(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Username': username,
          'Email': email,
          'Password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        // السطر ده هيطبعلك في الـ Console تحت رسالة الخطأ الحقيقية من السيرفر
        debugPrint("Server Error: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("SignUp Error: $e");
      return false;
    }
  }

  /// ========================================
  /// 3. دالة تحديث الملف الشخصي (Update Profile)
  /// ========================================
  static Future<bool> updateProfile({required String name, String? newPassword}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawCookie = prefs.getString('jwt_cookie');
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      // 🚀 إرسال الكوكي مع الطلب للمصادقة في الباك إند
      if (rawCookie != null && rawCookie.isNotEmpty) {
        headers['Cookie'] = rawCookie.split(';').first;
      }

      // ⚠️ تأكد من الرابط هنا. إذا كان الـ Controller الخاص بك هو AuthController
      // قد تحتاج لتغيير الرابط إلى: '$baseUrl/Auth/update-profile'
      final response = await http.put(
        Uri.parse('$baseUrl/Staff/update-profile'), 
        headers: headers,
        body: jsonEncode({
          'Name': name,
          'NewPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        // تحديث الاسم محلياً ليتغير في التطبيق فوراً بدون الحاجة لتسجيل الخروج
        await prefs.setString('username', name);
        return true;
      } else {
        debugPrint("UpdateProfile Failed: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("UpdateProfile Error: $e");
      return false;
    }
  }

  /// ========================================
  /// 4. دالة تسجيل الخروج (Sign Out)
  /// ========================================
  static Future<bool> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawCookie = prefs.getString('jwt_cookie');

      try {
        final headers = <String, String>{
          'Content-Type': 'application/json',
        };

        if (rawCookie != null && rawCookie.isNotEmpty) {
          final cookieValue = rawCookie.split(';').first;
          headers['Cookie'] = cookieValue;
        }

        final response = await http.post(
          Uri.parse('$baseUrl/Auth/logout'),
          headers: headers,
        );

        debugPrint("Logout Status: ${response.statusCode}");
        debugPrint("Logout Response: ${response.body}");
      } catch (e) {
        debugPrint("Server Logout Error: $e");
      }

      // Clear local session (مسح البيانات من الذاكرة)
      await prefs.remove('jwt_cookie');
      await prefs.remove('username');
      await prefs.remove('role');
      await prefs.remove('email'); // 🚀 مسح الإيميل أيضاً
      
      await prefs.setBool('isLoggedIn', false);

      return true;
    } catch (e) {
      debugPrint("SignOut Error: $e");
      return false;
    }
  }

  /// ========================================
  /// 5. دالة جلب بيانات المستخدم محلياً (Get Local User Data)
  /// ========================================
  static Future<Map<String, String>> getLocalUserData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'username': prefs.getString('username') ?? 'User',
      'role': prefs.getString('role') ?? 'user',
      'email': prefs.getString('email') ?? '', // 🚀 استرجاع الإيميل لعرضه
    };
  }

  static Future<bool> deleteAccount() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final rawCookie = prefs.getString('jwt_cookie');

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    // إرسال JWT Cookie مع الطلب
    if (rawCookie != null && rawCookie.isNotEmpty) {
      headers['Cookie'] = rawCookie.split(';').first;
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/Auth/delete-account'),
      headers: headers,
    );

    debugPrint('Delete Account Status: ${response.statusCode}');
    debugPrint('Delete Account Response: ${response.body}');

    return response.statusCode == 200;
  } catch (e) {
    debugPrint('Delete Account Error: $e');
    return false;
  }
}

  
}
