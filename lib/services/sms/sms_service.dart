import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:permission_handler/permission_handler.dart';

import '../transaction_ingest_service.dart';
import 'sms_channel.dart';

class SmsService {
  SmsService({required TransactionIngestService ingest}) : _ingest = ingest;

  static const _channel = MethodChannel('app.sms/receive');

  final TransactionIngestService _ingest;
  bool _initialized = false;
  bool _draining = false;
  bool _drainAgain = false;

  Future<void> initialize() async {
    if (_initialized) return;
    SmsChannel.initialize(
      onSmsQueued: _drainPendingSms,
      onSms: (payload) async {
        await _onSms(payload);
      },
    );
    if (Platform.isAndroid) {
      await _drainPendingSms();
    }
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return false;
    final sms = await Permission.sms.request();
    if (sms.isGranted) {
      await _drainPendingSms();
    }
    return sms.isGranted;
  }

  Future<bool> hasPermissions() async {
    if (!Platform.isAndroid) return false;
    return Permission.sms.isGranted;
  }

  Future<void> _drainPendingSms() async {
    if (!Platform.isAndroid) return;
    if (_draining) {
      _drainAgain = true;
      _log('Drain already running; scheduling another pass');
      return;
    }

    _draining = true;
    final processedIds = <String>[];

    try {
      final pending =
          await _channel.invokeListMethod<dynamic>('fetchPendingSms') ?? [];
      _log('Fetched ${pending.length} queued SMS message(s)');

      for (final item in pending) {
        final payload = Map<String, dynamic>.from(item as Map);
        final result = await _onSms(payload);

        final id = payload['id'] as String?;
        if (id != null && id.isNotEmpty) {
          processedIds.add(id);
        }
        _log('Ingest result: ${result.status.name}');
      }

      if (processedIds.isNotEmpty) {
        await _channel.invokeMethod('ackPendingSms', {'ids': processedIds});
        _log('Acknowledged ${processedIds.length} queued SMS message(s)');
      }
    } catch (error, stackTrace) {
      _log('Drain failed: $error');
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'pulse_money.sms',
          context: ErrorDescription('draining queued SMS messages'),
        ),
      );
    } finally {
      _draining = false;
      if (_drainAgain) {
        _drainAgain = false;
        await _drainPendingSms();
      }
    }
  }

  Future<IngestResult> _onSms(Map<String, dynamic> payload) async {
    final smsId = payload['id'] as String? ??
        payload['smsId'] as String? ??
        DateTime.now().millisecondsSinceEpoch.toString();
    return _ingest.ingestSms(
      smsId: smsId,
      sender:
          payload['sender'] as String? ?? payload['address'] as String? ?? '',
      body: payload['body'] as String? ?? '',
      timestampMs:
          payload['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  void _log(String message) {
    debugPrint('PulseMoneySmsDart: $message');
  }
}
