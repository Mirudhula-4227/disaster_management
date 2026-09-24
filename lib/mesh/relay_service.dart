import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../db/database_helper.dart';
import '../models/report.dart';
import 'nearby_service.dart';

class MessageType {
  static const idList = 'id_list';
  static const request = 'request';
  static const report = 'report';
}

class RelayService {
  static final RelayService instance = RelayService._internal();
  RelayService._internal();

  final Set<String> _handshakedPeers = {};

  void Function()? onReportsChanged;

  void init() {
    NearbyService.instance.addPayloadListener(_handleIncomingPayload);
    NearbyService.instance.addPeersChangedListener(_checkForNewConnections);
  }

  void _checkForNewConnections() {
    for (final peer in NearbyService.instance.peers.values) {
      if (peer.status == PeerStatus.connected &&
          !_handshakedPeers.contains(peer.endpointId)) {
        _handshakedPeers.add(peer.endpointId);
        _sendIdList(peer.endpointId);
      }
      if (peer.status == PeerStatus.disconnected) {
        _handshakedPeers.remove(peer.endpointId);
      }
    }
  }

  Future<void> _sendIdList(String endpointId) async {
    final reports = await DatabaseHelper.instance.getAllReports();
    final ids = reports.map((r) => r.id).toList();

    await NearbyService.instance.sendToPeer(endpointId, {
      'type': MessageType.idList,
      'ids': ids,
    });
  }

  Future<void> _handleIncomingPayload(String endpointId, Uint8List bytes) async {
    Map<String, dynamic> message;
    try {
      message = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Failed to decode relay message: $e');
      return;
    }

    switch (message['type']) {
      case MessageType.idList:
        await _handleIdList(endpointId, message);
        break;
      case MessageType.request:
        await _handleRequest(endpointId, message);
        break;
      case MessageType.report:
        await _handleIncomingReport(message);
        break;
      default:
        debugPrint('Unknown relay message type: ${message['type']}');
    }
  }

  Future<void> _handleIdList(String endpointId, Map<String, dynamic> message) async {
    final incomingIds = List<String>.from(message['ids'] as List);
    final missingIds = await DatabaseHelper.instance.filterUnknownIds(incomingIds);

    if (missingIds.isEmpty) return;

    await NearbyService.instance.sendToPeer(endpointId, {
      'type': MessageType.request,
      'ids': missingIds,
    });
  }

  Future<void> _handleRequest(String endpointId, Map<String, dynamic> message) async {
    final requestedIds = List<String>.from(message['ids'] as List);

    final allReports = await DatabaseHelper.instance.getAllReports();
    final toSend = allReports
        .where((r) => requestedIds.contains(r.id))
        .toList()
      ..sort((a, b) =>
          (b.priorityScore ?? 0).compareTo(a.priorityScore ?? 0));

    for (final report in toSend) {
      await NearbyService.instance.sendToPeer(endpointId, {
        'type': MessageType.report,
        'report': report.toMap(),
      });
    }
  }

  Future<void> _handleIncomingReport(Map<String, dynamic> message) async {
    final map = Map<String, dynamic>.from(message['report'] as Map);
    final incoming = Report.fromMap(map);

    final existing = await DatabaseHelper.instance.getReportById(incoming.id);

    if (existing != null && existing.status == 'synced') return;

    final toStore = incoming.copyWith(status: 'relayed');

    await DatabaseHelper.instance.insertReport(toStore);
    onReportsChanged?.call();
  }
}
