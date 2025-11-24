import 'dart:convert';
import 'package:http/http.dart' as http;

class EspService {
  final String ip;
  EspService(this.ip);

  Uri _uri(String path) => Uri.parse('http://$ip$path');

  Future<bool> ping() async {
    try {
      final r = await http.get(_uri('/status')).timeout(const Duration(seconds: 2));
      return r.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getStatus() async {
    try {
      final r = await http.get(_uri('/status')).timeout(const Duration(seconds: 3));
      if (r.statusCode == 200) return json.decode(r.body) as Map<String, dynamic>;
    } catch (e) {}
    return null;
  }

  Future<List<dynamic>?> getSchedules() async {
    try {
      final r = await http.get(_uri('/schedule')).timeout(const Duration(seconds: 4));
      if (r.statusCode == 200) return json.decode(r.body) as List<dynamic>;
    } catch (e) {}
    return null;
  }

  Future<bool> postSchedules(List<Map<String, dynamic>> schedules) async {
    try {
      final r = await http.post(_uri('/schedule'), headers: {'Content-Type': 'application/json'}, body: json.encode(schedules)).timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> ring({int durationMs = 5000}) async {
    try {
      final r = await http.post(_uri('/ring'), headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: 'duration_ms=$durationMs').timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
