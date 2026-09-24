import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import '../db/database_helper.dart';
import 'nearby_service.dart';
import 'mesh_permissions.dart';

class MeshScheduler {
  static final MeshScheduler instance = MeshScheduler._internal();
  MeshScheduler._internal();

  final Battery _battery = Battery();

  Timer? _cycleTimer;
  bool _isRunning = false;
  bool _isActiveWindow = false;

  void Function(String statusLabel)? onStatusChanged;

  static const Duration _scanBurstDuration = Duration(seconds: 15);

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;
    await _runCycle();
  }

  Future<void> stop() async {
    _isRunning = false;
    _cycleTimer?.cancel();
    await NearbyService.instance.stopAll();
    _isActiveWindow = false;
  }

  bool get isRunning => _isRunning;

  Future<void> _runCycle() async {
    if (!_isRunning) return;

    final batteryLevel = await _battery.batteryLevel;
    final hasCriticalPending = await _hasCriticalPendingReports();

    final belowCriticalThreshold = batteryLevel < 20;

    if (belowCriticalThreshold && !hasCriticalPending) {
      _isActiveWindow = false;
      debugPrint(
        'MeshScheduler: battery low ($batteryLevel%), staying passive',
      );
      onStatusChanged?.call('Low battery ($batteryLevel%) — passive mode');
      _scheduleNextCycle(batteryLevel, hasCriticalPending);
      return;
    }

    final permitted = await MeshPermissions.requestAll();
    if (!permitted) {
      debugPrint('MeshScheduler: permissions not granted, cannot scan');
      _scheduleNextCycle(batteryLevel, hasCriticalPending);
      return;
    }

    _isActiveWindow = true;
    final myName = 'phone-${DateTime.now().millisecondsSinceEpoch % 1000}';
    await NearbyService.instance.startAdvertising(myName);
    await NearbyService.instance.startDiscovery(myName);
    onStatusChanged?.call(
      hasCriticalPending
          ? 'Scanning — critical report pending ($batteryLevel%)'
          : 'Scanning ($batteryLevel%)',
    );

    Timer(_scanBurstDuration, () async {
      if (!_isRunning) return;
      _isActiveWindow = false;
      onStatusChanged?.call('Idle until next scan ($batteryLevel%)');
      _scheduleNextCycle(batteryLevel, hasCriticalPending);
    });
  }

  void _scheduleNextCycle(int batteryLevel, bool hasCriticalPending) {
    final interval = _intervalFor(batteryLevel, hasCriticalPending);
    debugPrint(
      'MeshScheduler: next scan in ${interval.inSeconds}s '
      '(battery: $batteryLevel%, critical pending: $hasCriticalPending)',
    );
    _cycleTimer = Timer(interval, _runCycle);
  }

  Duration _intervalFor(int batteryLevel, bool hasCriticalPending) {
    if (hasCriticalPending) {
      return const Duration(seconds: 30);
    }
    if (batteryLevel >= 60) {
      return const Duration(minutes: 1);
    }
    if (batteryLevel >= 30) {
      return const Duration(minutes: 3);
    }
    return const Duration(minutes: 6);
  }

  Future<bool> _hasCriticalPendingReports() async {
    final unsynced = await DatabaseHelper.instance.getUnsyncedReports();
    return unsynced.any((r) => r.finalSeverity == 'critical');
  }

  bool get isInActiveWindow => _isActiveWindow;
}
