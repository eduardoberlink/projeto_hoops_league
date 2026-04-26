import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000";

  static String? token;

  static Map<String, String> get headers {
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  static Future<void> salvarToken(String t) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', t);
    token = t;
  }

  static Future<void> carregarToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
  }

  static Future<bool> login(String email, String senha) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: headers,
      body: jsonEncode({"email": email, "senha": senha}),
    );

    print("LOGIN STATUS: ${response.statusCode}");
    print("LOGIN BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await salvarToken(data["access_token"]);
      return true;
    }

    return false;
  }

  static Future<bool> register(Map<String, dynamic> user) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/criar-conta"),
      headers: headers,
      body: jsonEncode(user),
    );

    print("REGISTER STATUS: ${response.statusCode}");
    print("REGISTER BODY: ${response.body}");

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    final response = await http.get(
      Uri.parse("$baseUrl/auth/me"),
      headers: headers,
    );

    print("PROFILE STATUS: ${response.statusCode}");
    print("PROFILE BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }


static Future<bool> deletarConta() async {
  final response = await http.put(
    Uri.parse("$baseUrl/auth/deletar-usuario"),
    headers: headers,
  );
  print("DELETE CONTA STATUS: ${response.statusCode}");
  print("DELETE CONTA BODY: ${response.body}");
  if (response.statusCode == 200) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token'); 
    token = null;               
  }
  return response.statusCode == 200;
}

  static Future<bool> updateProfile(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse("$baseUrl/auth/editar-me"),
      headers: headers,
      body: jsonEncode(data),
    );

    print("UPDATE PROFILE STATUS: ${response.statusCode}");
    print("UPDATE PROFILE BODY: ${response.body}");

    return response.statusCode == 200;
  }

  static Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse("$baseUrl$endpoint"),
      headers: headers,
    );

    print("GET STATUS: ${response.statusCode}");
    print("GET BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }

  static Future<bool> put(String endpoint, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse("$baseUrl$endpoint"),
      headers: headers,
      body: jsonEncode(body),
    );

    print("PUT STATUS: ${response.statusCode}");
    print("PUT BODY: ${response.body}");

    return response.statusCode == 200;
  }

  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    return await http.post(
      Uri.parse("$baseUrl$endpoint"),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  static Future<bool> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse("$baseUrl$endpoint"),
      headers: headers,
    );

    print("DELETE STATUS: ${response.statusCode}");
    print("DELETE BODY: ${response.body}");

    return response.statusCode == 200;
  }
}
