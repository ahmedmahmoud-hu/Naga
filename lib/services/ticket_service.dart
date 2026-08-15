import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TicketService {
  static final String baseUrl = dotenv.env['API_BASE_URL'] ?? "http://10.0.2.2:5021/api";

  /// ========================================
  /// جلب بلاغات المستخدم الحالي
  /// ========================================
  static Future<List<dynamic>> getMyTickets() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    final cookie = prefs.getString('jwt_cookie') ?? '';

    final url = '$baseUrl/Tickets/mytickets';

    debugPrint('======================================');
    debugPrint('GET MY TICKETS');
    debugPrint('URL: $url');
    debugPrint('COOKIE: $cookie');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Cookie': cookie,
      },
    );

    debugPrint('STATUS CODE: ${response.statusCode}');
    debugPrint('RESPONSE BODY: ${response.body}');
    debugPrint('======================================');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        debugPrint('TICKETS FROM API: ${decoded.length}');
        return decoded;
      }

      debugPrint('ERROR: Response is not a List');
      return [];
    }

    debugPrint(
      'FAILED GET MY TICKETS: ${response.statusCode}',
    );

    return [];
  } catch (e, stackTrace) {
    debugPrint('GetMyTickets Error: $e');
    debugPrint('$stackTrace');
    return [];
  }
}

/// ========================================
  /// إنشاء بلاغ جديد (Create Ticket)
  /// ========================================
  static Future<bool> createTicket({
    required String description,
    required List<String> pollutionTypes,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtCookie = prefs.getString('jwt_cookie') ?? '';
      final sessionCookie = prefs.getString('session_cookie') ?? ''; // 🚀 جلب كود الجلسة

      // 🚀 دمج الكوكيز (الـ JWT مع الـ Session)
      String combinedCookies = '';
      if (jwtCookie.isNotEmpty) combinedCookies += '$jwtCookie; ';
      if (sessionCookie.isNotEmpty) combinedCookies += sessionCookie;

      final url = '$baseUrl/Tickets/create';

      final payload = {
        'Description': description,
        'PollutionTypes': pollutionTypes,
        'Latitude': latitude,
        'Longitude': longitude,
        'Address': address,
      };

      debugPrint('======================================');
      debugPrint('POST CREATE TICKET');
      debugPrint('URL: $url');
      debugPrint('COOKIES: $combinedCookies'); // للتأكد إن الكوكي بيتبعت
      debugPrint('PAYLOAD: $payload');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': combinedCookies, // 🚀 إرسال الكوكيز المدمجة هنا
        },
        body: jsonEncode(payload),
      );

      debugPrint('STATUS CODE: ${response.statusCode}');
      debugPrint('RESPONSE BODY: ${response.body}');
      debugPrint('======================================');

      if (response.statusCode == 200) {
        // يمكنك مسح الـ session_cookie بعد النجاح لتنظيف الذاكرة
        await prefs.remove('session_cookie'); 
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      debugPrint('CreateTicket Error: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }
}