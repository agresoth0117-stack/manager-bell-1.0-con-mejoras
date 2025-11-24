import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weekly_schedule_provider.dart';
import '../models/hour_item.dart';
import '../models/day_schedule.dart';
import '../models/schedule_group.dart';

class SchedulesWeeklyScreen extends StatelessWidget {
  const SchedulesWeeklyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WeeklyScheduleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Horarios Semanales"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.notifyListeners(),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateGroupDialog(context),
        child: const Icon(Icons.add),
      ),

      body: ListView.builder(
        itemCount: provider.groups.length,
        itemBuilder: (context, index) {
          final group = provider.groups[index];
          return _groupCard(context, group);
        },
      ),
    );
  }

  // --------------------------------------------------------
  // Tarjeta principal de cada "Grupo de Horarios"
  // --------------------------------------------------------
  Widget _groupCard(BuildContext context, ScheduleGroup group) {
    final provider = Provider.of<WeeklyScheduleProvider>(context);

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      child: ExpansionTile(
        title: Text(group.name),
        children: [
          ...group.days.map((d) => _dayTile(context, group, d)).toList(),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.upload),
                label: const Text("Activar en dispositivo"),
                onPressed: () async {
                  bool ok = await provider.activateSchedule(
                    context: context,
                    groupId: group.id,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? "Horario enviado al dispositivo ✓"
                            : "No se pudo enviar el horario",
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  provider.deleteGroup(group.id);
                },
              )
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // Día de la semana (lista de horas)
  // --------------------------------------------------------
  Widget _dayTile(
      BuildContext context, ScheduleGroup group, DaySchedule day) {

    final provider = Provider.of<WeeklyScheduleProvider>(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      color: const Color(0xFFF5F5F5),
      child: ExpansionTile(
        title: Text("${day.dayName} (${day.dayLetter})"),
        children: [
          if (day.hours.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "No hay horas asignadas",
                style: TextStyle(color: Colors.grey),
              ),
            ),

          ...day.hours.map(
            (h) => ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(h.formatted()),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  provider.deleteHour(
                    groupId: group.id,
                    dayLetter: day.dayLetter,
                    hour: h,
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          ElevatedButton.icon(
            onPressed: () => _showAddHourDialog(context, group, day),
            icon: const Icon(Icons.add),
            label: const Text("Agregar hora"),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // Diálogo para crear un GRUPO
  // --------------------------------------------------------
  void _showCreateGroupDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Nuevo Horario"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: "Nombre del horario",
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Guardar"),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Provider.of<WeeklyScheduleProvider>(
                    context,
                    listen: false,
                  ).addGroup(controller.text.trim());
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------------
  // Diálogo para agregar hora a un día
  // --------------------------------------------------------
  void _showAddHourDialog(
      BuildContext context, ScheduleGroup group, DaySchedule day) {

    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("Agregar hora (${day.dayName})"),
          content: ElevatedButton(
            onPressed: () async {
              TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: selectedTime,
              );
              if (picked != null) {
                selectedTime = picked;
              }
            },
            child: const Text("Seleccionar hora"),
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Agregar"),
              onPressed: () {
                Provider.of<WeeklyScheduleProvider>(
                  context,
                  listen: false,
                ).addHour(
                  groupId: group.id,
                  dayLetter: day.dayLetter,
                  hour: HourItem(
                    hour: selectedTime.hour,
                    minute: selectedTime.minute,
                  ),
                );

                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }
}
