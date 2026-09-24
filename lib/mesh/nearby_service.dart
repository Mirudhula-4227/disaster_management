import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';

const String kServiceId = 'com.example.sos_mesh_app';

enum PeerStatus { discovered, connecting, connected, disconnected }

class NearbyPeer {
  final String endpointId;
  final String deviceName;
  PeerStatus status;

  NearbyPeer({
    required this.endpointId,
    required this.deviceName,
    required this.status,
  });
}

class NearbyService {
  static final NearbyService instance = NearbyService._internal();
  NearbyService._internal();

  final Nearby _nearby = Nearby();
  final Map<String, NearbyPeer> peers = {};

  final List<void Function()> _peerListeners = [];
  final List<void Function(String endpointId, Uint8List payload)> _payloadListeners = [];

  void addPeersChangedListener(void Function() listener) {
    _peerListeners.add(listener);
  }

  void removePeersChangedListener(void Function() listener) {
    _peerListeners.remove(listener);
  }

  void addPayloadListener(void Function(String endpointId, Uint8List payload) listener) {
    _payloadListeners.add(listener);
  }

  void _notifyPeersChanged() {
    for (final listener in _peerListeners) {
      listener();
    }
  }

  void _notifyPayloadReceived(String endpointId, Uint8List payload) {
    for (final listener in _payloadListeners) {
      listener(endpointId, payload);
    }
  }

  bool _isAdvertising = false;
  bool _isDiscovering = false;

  Future<void> startAdvertising(String myDeviceName) async {
    if (_isAdvertising) return;
    try {
      await _nearby.startAdvertising(
        myDeviceName,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: kServiceId,
      );
      _isAdvertising = true;
    } catch (e) {
      debugPrint('startAdvertising failed: $e');
    }
  }

  Future<void> startDiscovery(String myDeviceName) async {
    if (_isDiscovering) return;
    try {
      await _nearby.startDiscovery(
        myDeviceName,
        Strategy.P2P_CLUSTER,
        onEndpointFound: (endpointId, deviceName, serviceId) {
          if (serviceId != kServiceId) return;
          peers[endpointId] = NearbyPeer(
            endpointId: endpointId,
            deviceName: deviceName,
            status: PeerStatus.discovered,
          );
          _notifyPeersChanged();

          _nearby.requestConnection(
            myDeviceName,
            endpointId,
            onConnectionInitiated: _onConnectionInitiated,
            onConnectionResult: _onConnectionResult,
            onDisconnected: _onDisconnected,
          );
        },
        onEndpointLost: (endpointId) {
          if (endpointId != null) {
            peers.remove(endpointId);
            _notifyPeersChanged();
          }
        },
        serviceId: kServiceId,
      );
      _isDiscovering = true;
    } catch (e) {
      debugPrint('startDiscovery failed: $e');
    }
  }

  Future<void> stopAll() async {
    await _nearby.stopAdvertising();
    await _nearby.stopDiscovery();
    await _nearby.stopAllEndpoints();
    _isAdvertising = false;
    _isDiscovering = false;
  }

  void _onConnectionInitiated(String endpointId, ConnectionInfo info) {
    peers[endpointId] = NearbyPeer(
      endpointId: endpointId,
      deviceName: info.endpointName,
      status: PeerStatus.connecting,
    );
    _notifyPeersChanged();

    _nearby.acceptConnection(
      endpointId,
      onPayLoadRecieved: (endpointId, payload) {
        if (payload.type == PayloadType.BYTES && payload.bytes != null) {
          _notifyPayloadReceived(endpointId, payload.bytes!);
        }
      },
    );
  }

  void _onConnectionResult(String endpointId, Status status) {
    final peer = peers[endpointId];
    if (peer == null) return;
    peer.status = status == Status.CONNECTED
        ? PeerStatus.connected
        : PeerStatus.disconnected;
    _notifyPeersChanged();
  }

  void _onDisconnected(String endpointId) {
    final peer = peers[endpointId];
    if (peer != null) {
      peer.status = PeerStatus.disconnected;
      _notifyPeersChanged();
    }
  }

  Future<void> sendToPeer(String endpointId, Map<String, dynamic> message) async {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(message)));
    await _nearby.sendBytesPayload(endpointId, bytes);
  }

  Future<void> broadcast(Map<String, dynamic> message) async {
    final connectedIds = peers.values
        .where((p) => p.status == PeerStatus.connected)
        .map((p) => p.endpointId);
    for (final id in connectedIds) {
      await sendToPeer(id, message);
    }
  }
}
