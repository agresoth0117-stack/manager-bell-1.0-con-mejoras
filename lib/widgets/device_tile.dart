import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../providers/device_provider.dart';
import '../screens/schedules_screen.dart';

class DeviceTile extends StatefulWidget {
  final Device device;

  const DeviceTile({super.key, required this.device});

  @override
  State<DeviceTile> createState() => _DeviceTileState();
}

class _DeviceTileState extends State<DeviceTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapAnim;

  @override
  void initState() {
    super.initState();
    _tapAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.92,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _tapAnim.dispose();
    super.dispose();
  }

  void _openSchedulesScreen() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: SchedulesScreen(deviceId: widget.device.id),
        ),
        transitionsBuilder: (_, anim, __, child) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));

          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: slide,
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;

    return ScaleTransition(
      scale: _tapAnim,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await _tapAnim.reverse();
          await _tapAnim.forward();
          _openSchedulesScreen();
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 3),
              )
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.memory_rounded,
                size: 40,
                color: device.online ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  device.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                device.online ? "ONLINE" : "OFF",
                style: TextStyle(
                  color: device.online ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

