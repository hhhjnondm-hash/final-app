import 'package:flutter/foundation.dart';

class SourceHealthSample {
  final String provider;
  final String endpoint;
  final bool success;
  final int latencyMs;
  final DateTime at;
  final String? failureType;

  const SourceHealthSample({
    required this.provider,
    required this.endpoint,
    required this.success,
    required this.latencyMs,
    required this.at,
    this.failureType,
  });
}

class SourceHealthSnapshot {
  final String provider;
  final String endpoint;
  int successCount = 0;
  int failureCount = 0;
  int lastLatencyMs = 0;
  DateTime? lastSuccess;
  DateTime? lastFailure;
  String? lastFailureType;

  SourceHealthSnapshot({required this.provider, required this.endpoint});

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'endpoint': endpoint,
        'success': successCount,
        'failure': failureCount,
        'latency': lastLatencyMs,
        'lastSuccess': lastSuccess?.toIso8601String(),
        'lastFailure': lastFailure?.toIso8601String(),
        'failureType': lastFailureType,
      };
}

/// Lightweight in-memory source health tracker for development diagnostics.
class SourceHealthMonitor {
  static final SourceHealthMonitor _instance = SourceHealthMonitor._internal();
  factory SourceHealthMonitor() => _instance;
  SourceHealthMonitor._internal();

  final Map<String, SourceHealthSnapshot> _byKey = {};

  Future<T> track<T>({
    required String provider,
    required String endpoint,
    required Future<T> Function() action,
    String Function(Object error)? classify,
  }) async {
    final sw = Stopwatch()..start();
    try {
      final result = await action();
      sw.stop();
      record(SourceHealthSample(
        provider: provider,
        endpoint: endpoint,
        success: true,
        latencyMs: sw.elapsedMilliseconds,
        at: DateTime.now(),
      ));
      return result;
    } catch (e) {
      sw.stop();
      record(SourceHealthSample(
        provider: provider,
        endpoint: endpoint,
        success: false,
        latencyMs: sw.elapsedMilliseconds,
        at: DateTime.now(),
        failureType: classify?.call(e) ?? e.runtimeType.toString(),
      ));
      rethrow;
    }
  }

  void record(SourceHealthSample sample) {
    final key = '${sample.provider}|${sample.endpoint}';
    final snap = _byKey.putIfAbsent(
      key,
      () => SourceHealthSnapshot(
        provider: sample.provider,
        endpoint: sample.endpoint,
      ),
    );
    snap.lastLatencyMs = sample.latencyMs;
    if (sample.success) {
      snap.successCount++;
      snap.lastSuccess = sample.at;
    } else {
      snap.failureCount++;
      snap.lastFailure = sample.at;
      snap.lastFailureType = sample.failureType;
    }
    if (kDebugMode) {
      debugPrint(
        '[HEALTH] ${sample.provider} ${sample.endpoint} '
        '${sample.success ? 'ok' : 'fail'} ${sample.latencyMs}ms '
        '${sample.failureType ?? ''}',
      );
    }
  }

  List<SourceHealthSnapshot> get snapshots => _byKey.values.toList();

  Map<String, dynamic> toReport() => {
        'sources': snapshots.map((s) => s.toJson()).toList(),
      };
}
