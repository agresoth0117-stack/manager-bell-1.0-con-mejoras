import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/schedule_entry.dart';

class ScheduleProvider extends ChangeNotifier {
  List<ScheduleEntry> schedules = [];

  /// Cargar horarios desde el ESP8266
  Future<bool> loadFromDevice(String ip) async {
    try {
      final url = Uri.parse("http://$ip/schedule");
      final res = await http.get(url).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        schedules = data.map((j) => ScheduleEntry.fromJson(j)).toList();
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Guardar horarios en el ESP8266
  Future<bool> saveToDevice(String ip) async {
    try {
      final url = Uri.parse("http://$ip/schedule");
      final jsonBody = jsonEncode(schedules.map((e) => e.toJson()).toList());

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonBody,
      ).timeout(const Duration(seconds: 4));

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// CRUD local
  void add(ScheduleEntry e) {
    schedules.add(e);
    notifyListeners();
  }

  void update(int index, ScheduleEntry e) {
    schedules[index] = e;
    notifyListeners();
  }

  void remove(int index) {
    schedules.removeAt(index);
    notifyListeners();
  }

  void clear() {
    schedules.clear();
    notifyListeners();
  }
}

