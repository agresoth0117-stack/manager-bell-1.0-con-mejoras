import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule.dart';
import '../providers/schedule_provider.dart';

class ScheduleForm extends StatefulWidget {
  final ScheduleItem? edit;
  const ScheduleForm({super.key, this.edit});

  @override
  State<ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends State<ScheduleForm> {
  final _nameCtrl = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 7, minute: 0);
  int _duration = 5000;
  List<int> _days = [1,2,3,4,5]; // default Mon-Fri

  @override
  void initState() {
    super.initState();
    if (widget.edit != null) {
      final e = widget.edit!;
      _nameCtrl.text = e.name;
      _time = TimeOfDay(hour: e.hour, minute: e.minute);
      _duration = e.durationMs;
      _days = List.from(e.days);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.edit==null ? 'Nuevo horario' : 'Editar horario')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nombre (ej: Receso mañana)')),
            const SizedBox(height: 12),
            ListTile(
              title: Text('Hora: ${_time.format(context)}'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final t = await showTimePicker(context: context, initialTime: _time);
                if (t != null) setState(() => _time = t);
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Duración (ms):'),
                const SizedBox(width: 8),
                Expanded(child: TextField(keyboardType: TextInputType.number, decoration: InputDecoration(hintText: '$_duration'), onChanged: (v){ final val=int.tryParse(v); if(val!=null) _duration=val; })),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: List.generate(7, (i) {
                final labels = ['D','L','M','X','J','V','S'];
                final selected = _days.contains(i);
                return FilterChip(
                  label: Text(labels[i]),
                  selected: selected,
                  onSelected: (s) {
                    setState(() {
                      if (s) _days.add(i); else _days.remove(i);
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                final name = _nameCtrl.text.isEmpty ? '${_time.hour.toString().padLeft(2,'0')}:${_time.minute.toString().padLeft(2,'0')}' : _nameCtrl.text;
                final item = ScheduleItem(name: name, hour: _time.hour, minute: _time.minute, deviceIds: [], durationMs: _duration, days: _days);
                Navigator.pop(context, item);
              },
              child: const Text('Guardar horario'),
            )
          ],
        ),
      ),
    );
  }
}
