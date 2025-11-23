class ScheduleEntry {
  int h;        // hora (0–23)
  int m;        // minuto (0–59)
  String d;     // días como "LMXJVSD"

  ScheduleEntry({
    required this.h,
    required this.m,
    required this.d,
  });

  /// Convierte a JSON para enviarlo al ESP8266
  Map<String, dynamic> toJson() => {
        "h": h,
        "m": m,
        "d": d,
      };

  /// Carga desde JSON recibido del ESP8266
  factory ScheduleEntry.fromJson(Map<String, dynamic> j) {
    return ScheduleEntry(
      h: j["h"] ?? 0,
      m: j["m"] ?? 0,
      d: j["d"] ?? "LMXJV",
    );
  }

  /// Formato legible en texto para la UI
  String get formattedTime =>
      "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";

  /// Convierte "LMXJVSD" → lista legible ["Lun", "Mar", ...]
  List<String> get readableDays {
    final map = {
      "L": "Lun",
      "M": "Mar",
      "X": "Mié",
      "J": "Jue",
      "V": "Vie",
      "S": "Sáb",
      "D": "Dom",
    };
    return d.split("").map((e) => map[e] ?? e).toList();
  }
}
