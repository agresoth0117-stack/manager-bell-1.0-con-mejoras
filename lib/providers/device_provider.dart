import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import '../models/device.dart';
import '../services/device_scanner.dart';

class DeviceProvider extends ChangeNotifier {
  final List<Device> _devices = [];
  List<Device> get devices => _devices;

  DeviceProvider() {
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('devices');
    if (raw != null) {
      final list = json.decode(raw) as List<dynamic>;
      for (var j in list) {
        _devices.add(Device.fromJson(Map<String, dynamic>.from(j)));
      }
    }
    notifyListeners();

    // Refresca online/offline al iniciar
    await refreshAll();
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
      'devices',
      json.encode(_devices.map((d) => d.toJson()).toList()),
    );
  }

  Future<void> addDevice(String name, String ip) async {
    final id = const Uuid().v4();
    _devices.add(Device(id: id, name: name, ip: ip));
    await _save();
    notifyListeners();
  }

  Future<void> removeDevice(String id) async {
    _devices.removeWhere((d) => d.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> updateDevice(Device device) async {
    final idx = _devices.indexWhere((d) => d.id == device.id);
    if (idx >= 0) {
      _devices[idx] = device;
      await _save();
      notifyListeners();
    }
  }

  /// Refresca estado ONLINE/OFFLINE para todos los dispositivos guardados
  Future<void> refreshAll() async {
    for (var d in _devices) {
      d.online = await _ping(d.ip);
    }
    notifyListeners();
    await _save();
  }

  Future<bool> _ping(String ip) async {
    try {
      final r = await http
          .get(Uri.parse('http://$ip/status'))
          .timeout(const Duration(seconds: 2));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Escanea la red y combina resultados con dispositivos existentes
  Future<void> scanAndMerge() async {
    final scanner = DeviceScanner();
    List found = await scanner.scanNetwork(); // List<ESPDevice>

    // Integrar dispositivos detectados
    for (var f in found) {
      final idx = _devices.indexWhere((d) => d.ip == f.ip);

      if (idx >= 0) {
        _devices[idx].name = f.hostname ?? _devices[idx].name;
        _devices[idx].online = true;
      } else {
        final id = const Uuid().v4();
        _devices.add(Device(
          id: id,
          name: f.hostname ?? "ESP",
          ip: f.ip,
          online: true,
        ));
      }
    }

    // Marcar como offline los que no aparecieron
    for (var d in _devices) {
      final present = found.any((x) => x.ip == d.ip);
      if (!present) d.online = false;
    }

    await _save();
    notifyListeners();
  }

  /// Enviar comando /ring
  Future<bool> ringDeviceByIp(String ip, {int durationMs = 5000}) async {
    try {
      final r = await http
          .post(
            Uri.parse('http://$ip/ring'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'duration_ms=$durationMs',
          )
          .timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> ringDevice(String id, {int durationMs = 5000}) async {
    final d = _devices.firstWhere((x) => x.id == id);
    final ok = await ringDeviceByIp(d.ip, durationMs: durationMs);
    d.online = ok;
    notifyListeners();
    await _save();
    return ok;
  }
}
