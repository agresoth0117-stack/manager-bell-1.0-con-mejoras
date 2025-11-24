import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_group.dart';
import '../models/day_schedule.dart';
import '../models/hour_item.dart';
import 'device_provider.dart';  // Para enviar horarios al ESP
import 'package:provider/provider.dart';

class WeeklyScheduleProvider extends ChangeNotifier {
  List<ScheduleGroup> _groups = [];

  List<ScheduleGroup> get groups => _groups;

  WeeklyScheduleProvider() {
    _loadFromStorage();
  }

  // ---------------------------------------------------------
  // Cargar y guardar horarios (persistencia local)
  // ---------------------------------------------------------
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString("weekly_schedules");

    if (data != null) {
      List decoded = jsonDecode(data);
      _groups = decoded.map((e) => ScheduleGroup.fromJson(e)).toList();
    } else {
      _createEmptyDefaultGroup();
    }

    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    String encoded = jsonEncode(_groups.map((e) => e.toJson()).toList());
    await prefs.setString("weekly_schedules", encoded);
  }

  void _createEmptyDefaultGroup() {
    _groups = [
      ScheduleGroup(
        id: "default",
        name: "Horario General",
        days: _generateEmptyWeek(),
      ),
    ];
  }

  List<DaySchedule> _generateEmptyWeek() {
    return [
      DaySchedule(dayName: "Lunes", dayLetter: "L", hours: []),
      DaySchedule(dayName: "Martes", dayLetter: "M", hours: []),
      DaySchedule(dayName: "Miércoles", dayLetter: "X", hours: []),
      DaySchedule(dayName: "Jueves", dayLetter: "J", hours: []),
      DaySchedule(dayName: "Viernes", dayLetter: "V", hours: []),
      DaySchedule(dayName: "Sábado", dayLetter: "S", hours: []),
      DaySchedule(dayName: "Domingo", dayLetter: "D", hours: []),
    ];
  }

  // ---------------------------------------------------------
  // CRUD de grupos (horarios semanales)
  // ---------------------------------------------------------
  void addGroup(String name) {
    _groups.add(
      ScheduleGroup(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        days: _generateEmptyWeek(),
      ),
    );
    _saveToStorage();
    notifyListeners();
  }

  void renameGroup(String id, String newName) {
    final group = _groups.firstWhere((g) => g.id == id);
    group.name = newName;
    _saveToStorage();
    notifyListeners();
  }

  void deleteGroup(String id) {
    _groups.removeWhere((g) => g.id == id);
    _saveToStorage();
    notifyListeners();
  }

  // ---------------------------------------------------------
  // Manejo de horas dentro de cada día
  // ---------------------------------------------------------
  void addHour({
    required String groupId,
    required String dayLetter,
    required HourItem hour,
  }) {
    final group = _groups.firstWhere((g) => g.id == groupId);
    final day = group.days.firstWhere((d) => d.dayLetter == dayLetter);

    day.hours.add(hour);
    day.hours.sort((a, b) => (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute));

    _saveToStorage();
    notifyListeners();
  }

  void deleteHour({
    required String groupId,
    required String dayLetter,
    required HourItem hour,
  }) {
    final group = _groups.firstWhere((g) => g.id == groupId);
    final day = group.days.firstWhere((d) => d.dayLetter == dayLetter);

    day.hours.removeWhere(
      (h) => h.hour == hour.hour && h.minute == hour.minute,
    );

    _saveToStorage();
    notifyListeners();
  }

  // ---------------------------------------------------------
  // ACTIVAR HORARIO EN EL ESP8266
  // ---------------------------------------------------------
    /// Activa (envía) un grupo de horarios al ESP seleccionado.
  /// Devuelve true si el ESP responde con 200.
  Future<bool> activateSchedule({
    required BuildContext context,
    required String groupId,
  }) async {
    final group = _groups.firstWhere((g) => g.id == groupId);

    // Convertir a formato plano que entiende el ESP
    final espJson = group.toESPJson(); // List<Map<String,dynamic>>

    // Obtener dispositivo seleccionado del DeviceProvider
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final selected = deviceProvider.selectedDevice;
    if (selected == null) {
      // Opcional: mostrar mensaje al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay dispositivo seleccionado')),
      );
      return false;
    }

    final ip = selected.ip;
    final url = Uri.parse('http://$ip/schedule');

    try {
      final res = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(espJson),
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        // Éxito: opcional recargar status del dispositivo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horario enviado correctamente')),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en el dispositivo: ${res.statusCode}')),
        );
        return false;
      }
    } catch (e) {
      // Falla de red / timeout
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: ${e.toString()}')),
      );
      return false;
    }
  }

}
