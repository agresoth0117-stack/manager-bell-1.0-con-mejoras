import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ESPDevice {
  final String ip;
  final String hostname;
  final String time;
  bool online;

  ESPDevice({
    required this.ip,
    required this.hostname,
    required this.time,
    this.online = true,
  });
}

class DeviceScanner {

  Future<String> _getLocalSubnet() async {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 &&
            !addr.address.startsWith("127")) {

          List<String> parts = addr.address.split('.');
          return "${parts[0]}.${parts[1]}.${parts[2]}.";
        }
      }
    }

    return "192.168.1.";
  }

  Future<List<ESPDevice>> scanNetwork() async {
    List<ESPDevice> foundDevices = [];
    String subnet = await _getLocalSubnet();

    List<Future> futures = [];

    for (int i = 1; i < 255; i++) {
      String ip = "$subnet$i";

      futures.add(
        http
            .get(Uri.parse("http://$ip/status"))
            .timeout(Duration(milliseconds: 500), onTimeout: () {
          return http.Response("", 408);
        }).then((response) {
          if (response.statusCode == 200) {
            try {
              var jsonData = jsonDecode(response.body);
              foundDevices.add(
                ESPDevice(
                  ip: jsonData["ip"],
                  hostname: jsonData["hostname"],
                  time: jsonData["time"],
                ),
              );
            } catch (_) {}
          }
        }).catchError((_) {})
      );
    }

    await Future.wait(futures);
    return foundDevices;
  }
}
