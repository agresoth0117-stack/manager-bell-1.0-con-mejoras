import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule_entry.dart';
import '../providers/schedule_provider.dart';
import '../providers/device_provider.dart';

class SchedulesScreen extends StatefulWidget {
  final String deviceId;

  const SchedulesScreen({super.key, required this.deviceId});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();

    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final deviceProv = Provider.of<DeviceProvider>(context, listen: false);
    final scheduleProv = Provider.of<ScheduleProvider>(context, listen: false);

    final device = deviceProv.devices
        .firstWhere((d) => d.id == widget.deviceId, orElse: () => deviceProv.devices.first);

    final ok = await scheduleProv.loadFromDevice(device.ip);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudieron cargar los horarios")),
      );
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _addNew() {
    _openEditDialog(onSave: (entry) {
      Provider.of<ScheduleProvider>(context, listen: false).add(entry);
    });
  }

  Future<void> _openEditDialog({
    ScheduleEntry? edit,
    required Function(ScheduleEntry) onSave,
  }) async {
    TimeOfDay selectedTime =
        TimeOfDay(hour: edit?.h ?? 7, minute: edit?.m ?? 0);

    final Set<String> selectedDays = {};
    if (edit != null) {
      for (var ch in edit.d.split('')) selectedDays.add(ch);
    } else {
      selectedDays.addAll(['L', 'M', 'X', 'J', 'V']);
    }

    await showDialog(
      context: context,
      builder: (c) {
        return StatefulBuilder(
          builder: (c, setStateDialog) {
            return AlertDialog(
              title: Text(edit == null ? 'Agregar horario' : 'Editar horario'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text(
                        "Hora: ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}"),
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (t != null) {
                        setStateDialog(() {
                          selectedTime = t;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final pair in [
                        ['L', 'Lun'],
                        ['M', 'Mar'],
                        ['X', 'Mié'],
                        ['J', 'Jue'],
                        ['V', 'Vie'],
                        ['S', 'Sáb'],
                        ['D', 'Dom'],
                      ])
                        FilterChip(
                          label: Text(pair[1]),
                          selected: selectedDays.contains(pair[0]),
                          onSelected: (sel) {
                            setStateDialog(() {
                              if (sel)
                                selectedDays.add(pair[0]);
                              else
                                selectedDays.remove(pair[0]);
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    if (selectedDays.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Debes seleccionar días")));
                      return;
                    }

                    final entry = ScheduleEntry(
                      h: selectedTime.hour,
                      m: selectedTime.minute,
                      d: selectedDays.join(),
                    );
                    onSave(entry);
                    Navigator.pop(c);
                  },
                  child: const Text('Guardar'),
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveToESP() async {
    final deviceProv = Provider.of<DeviceProvider>(context, listen: false);
    final scheduleProv = Provider.of<ScheduleProvider>(context, listen: false);

    final device = deviceProv.devices
        .firstWhere((d) => d.id == widget.deviceId, orElse: () => deviceProv.devices.first);

    final ok = await scheduleProv.saveToDevice(device.ip);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al guardar en el dispositivo")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Horarios guardados correctamente")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProv = Provider.of<ScheduleProvider>(context);

    return FadeTransition(
      opacity: _anim,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Horarios del dispositivo"),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveToESP,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addNew,
          child: const Icon(Icons.add),
        ),
        body: AnimatedList(
          key: ValueKey(scheduleProv.schedules.length),
          initialItemCount: scheduleProv.schedules.length,
          itemBuilder: (context, i, anim) {
            final e = scheduleProv.schedules[i];
            return FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: anim.drive(
                    Tween(begin: const Offset(0, 0.1), end: Offset.zero)),
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: ListTile(
                    title: Text(e.formattedTime),
                    subtitle: Text(e.readableDays.join(" • ")),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _openEditDialog(
                                edit: e,
                                onSave: (updated) {
                                  scheduleProv.update(i, updated);
                                });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            scheduleProv.remove(i);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
