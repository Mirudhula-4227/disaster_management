import 'package:flutter/material.dart';
import '../mesh/nearby_service.dart';
import '../mesh/mesh_scheduler.dart';

class NearbyDevicesScreen extends StatefulWidget {
  const NearbyDevicesScreen({super.key});

  @override
  State<NearbyDevicesScreen> createState() => _NearbyDevicesScreenState();
}

class _NearbyDevicesScreenState extends State<NearbyDevicesScreen> {
  bool _meshActive = false;
  String _statusLabel = 'Stopped';

  void _onPeersChanged() {
    if (mounted) setState(() {});
  }

  void _onStatusChanged(String label) {
    if (mounted) setState(() => _statusLabel = label);
  }

  @override
  void initState() {
    super.initState();
    NearbyService.instance.addPeersChangedListener(_onPeersChanged);
    MeshScheduler.instance.onStatusChanged = _onStatusChanged;
  }

  @override
  void dispose() {
    NearbyService.instance.removePeersChangedListener(_onPeersChanged);
    super.dispose();
  }

  Future<void> _toggleMesh() async {
    if (_meshActive) {
      await MeshScheduler.instance.stop();
      setState(() {
        _meshActive = false;
        _statusLabel = 'Stopped';
      });
    } else {
      await MeshScheduler.instance.start();
      setState(() => _meshActive = true);
    }
  }

  Color _statusColor(PeerStatus status) {
    switch (status) {
      case PeerStatus.connected:
        return Colors.green;
      case PeerStatus.connecting:
        return Colors.orange;
      case PeerStatus.discovered:
        return Colors.blueGrey;
      case PeerStatus.disconnected:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final peers = NearbyService.instance.peers.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Devices')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _toggleMesh,
                  icon: Icon(_meshActive ? Icons.stop : Icons.wifi_tethering),
                  label: Text(_meshActive ? 'Stop Mesh' : 'Start Mesh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _meshActive ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                if (_meshActive) ...[
                  const SizedBox(height: 8),
                  Text(
                    _statusLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: peers.isEmpty
                ? const Center(
                    child: Text(
                      'No devices found yet.\nStart the mesh on two phones '
                      'near each other.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: peers.length,
                    itemBuilder: (context, index) {
                      final peer = peers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _statusColor(peer.status),
                          child: const Icon(
                            Icons.smartphone,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(peer.deviceName),
                        subtitle: Text(peer.status.name),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
