import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // CONFIGURAÇÃO DE IP:
  // Android Emulator: 10.0.2.2
  // iOS Simulator / Web: 127.0.0.1
  static const String baseUrl = "http://127.0.0.1:8000"; 

  Future<List<dynamic>> fetchPlayers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/players'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erro ao carregar dados do servidor');
      }
    } catch (e) {
      throw Exception('Falha na conexão: $e');
    }
  }

  Future<http.Response> createPlayer(Map<String, dynamic> playerData) async {
    return await http.post(
      Uri.parse('$baseUrl/players'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(playerData),
    );
  }
}