class ScheduleItem {
  int? id;
  String name;
  int hour;
  int minute;
  List<String> deviceIds;
  int durationMs;
  List<int> days; // 0=Sun..6=Sat

  ScheduleItem({
    this.id,
    required this.name,
    required this.hour,
    required this.minute,
    required this.deviceIds,
    this.durationMs = 5000,
    required this.days,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'hour': hour,
        'minute': minute,
        'deviceIds': deviceIds.join(','),
        'durationMs': durationMs,
        'days': days.join(','),
      };

  factory ScheduleItem.fromMap(Map<String, dynamic> m) => ScheduleItem(
        id: m['id'],
        name: m['name'],
        hour: m['hour'],
        minute: m['minute'],
        deviceIds: (m['deviceIds'] as String).split(',').where((s) => s.isNotEmpty).toList(),
        durationMs: m['durationMs'],
        days: (m['days'] as String).split(',').map((s) => int.parse(s)).toList(),
      );

  static String daysToESPString(List<int> days) {
    final map = ['D', 'L', 'M', 'X', 'J', 'V', 'S'];
    return days.map((d) => map[d]).join();
  }
}
