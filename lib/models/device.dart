class Device {
  final String id;
  String name;
  String ip;
  bool linked;
  bool online;

  Device({
    required this.id,
    required this.name,
    required this.ip,
    this.linked = false,
    this.online = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ip': ip,
        'linked': linked ? 1 : 0,
        'online': online ? 1 : 0,
      };

  factory Device.fromJson(Map<String, dynamic> j) => Device(
        id: j['id'],
        name: j['name'] ?? '',
        ip: j['ip'],
        linked: (j['linked'] == 1 || j['linked'] == true),
        online: (j['online'] == 1 || j['online'] == true),
      );
}
