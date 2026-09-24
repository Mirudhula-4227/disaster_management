import 'package:flutter/material.dart';
import 'screens/sos_form_screen.dart';
import 'screens/nearby_devices_screen.dart';
import 'mesh/relay_service.dart';

void main() {
  RelayService.instance.init();
  runApp(const SosMeshApp());
}

class SosMeshApp extends StatelessWidget {
  const SosMeshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOS Mesh',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const RootNav(),
    );
  }
}

class RootNav extends StatefulWidget {
  const RootNav({super.key});

  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  int _index = 0;

  final _screens = const [
    SosFormScreen(),
    NearbyDevicesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.report),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.wifi_tethering),
            label: 'Mesh',
          ),
        ],
      ),
    );
  }
}
