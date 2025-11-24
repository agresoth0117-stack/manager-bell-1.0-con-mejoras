import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../providers/schedule_provider.dart';
import '../providers/device_provider.dart';
import 'schedule_form.dart';

class DeviceDetail extends StatefulWidget {
  final Device device;
  const DeviceDetail({super.key, required this.device});

  @override
  State<DeviceDetail> createState() => _DeviceDetailState();
}

class _DeviceDetailState extends State<DeviceDetail> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final sprov = Provider.of<ScheduleProvider>(context);
    final dprov = Provider.of<DeviceProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.device.name)),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('IP: ${widget.device.ip}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Probar timbre (5s)'),
              onPressed: () async {
                setState(() => loading = true);
                final ok = await dprov.ringDevice(widget.device.id);
                setState(() => loading = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Ok' : 'Error')));
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.sync),
              label: const Text('Cargar horarios desde dispositivo'),
              onPressed: () async {
                await sprov.loadFromDevice(widget.device.ip);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Horarios cargados')));
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: sprov.schedules.isEmpty
                  ? const Center(child: Text('No hay horarios cargados'))
                  : ListView.builder(
                      itemCount: sprov.schedules.length,
                      itemBuilder: (c, i) {
                        final it = sprov.schedules[i];
                        final daysStr = it.days.map((d) => ['D','L','M','X','J','V','S'][d]).join(', ');
                        return Card(
                          child: ListTile(
                            title: Text(it.name),
                            subtitle: Text('Días: $daysStr'),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.save),
        onPressed: () async {
          final prov = Provider.of<ScheduleProvider>(context, listen: false);
          final ok = await prov.saveToDevice(widget.device.ip, prov.schedules);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Guardado en dispositivo' : 'Error al guardar')));
        },
      ),
    );
  }
}
