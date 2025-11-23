import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../providers/schedule_provider.dart';
import '../widgets/device_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  bool scanning = false;

  @override
  Widget build(BuildContext context) {
    final deviceProv = Provider.of<DeviceProvider>(context);
    final scheduleProv = Provider.of<ScheduleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timbres Escuela'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Buscar dispositivos en la red",
            onPressed: scanning
                ? null
                : () async {
                    setState(() => scanning = true);
                    await deviceProv.scanAndMerge();
                    setState(() => scanning = false);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Escaneo completado')),
                    );
                  },
          ),
        ],
      ),

      body: _index == 0
          ? _devicesList(deviceProv)
          : _schedulesView(deviceProv, scheduleProv),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _onAdd(context),
        child: const Icon(Icons.add),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: 'Dispositivos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Horarios',
          ),
        ],
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }

  Widget _devicesList(DeviceProvider prov) {
    if (prov.devices.isEmpty) {
      return const Center(
        child: Text(
          'No hay dispositivos.\nPulsa el botón + o usa REFRESH para buscar.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: prov.devices.length,
      itemBuilder: (context, i) => DeviceTile(device: prov.devices[i]),
    );
  }

  Widget _schedulesView(DeviceProvider dprov, ScheduleProvider sprov) {
    return const Center(
      child: Text(
        'Seleccione un dispositivo para gestionar horarios.',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  void _onAdd(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) {
        final nameCtl = TextEditingController();
        final ipCtl = TextEditingController();

        return AlertDialog(
          title: const Text('Agregar dispositivo manualmente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtl,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: ipCtl,
                decoration: const InputDecoration(labelText: 'IP'),
                keyboardType: TextInputType.url,
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtl.text.isNotEmpty && ipCtl.text.isNotEmpty) {
                  await Provider.of<DeviceProvider>(context, listen: false)
                      .addDevice(nameCtl.text, ipCtl.text);
                  Navigator.pop(c);
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }
}
