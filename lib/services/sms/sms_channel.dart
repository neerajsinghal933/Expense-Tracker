import 'package:flutter/services.dart';

class SmsChannel {
  static const MethodChannel _channel = MethodChannel('app.sms/receive');

  static void initialize({
    required Future<void> Function() onSmsQueued,
    required Future<void> Function(Map<String, dynamic>) onSms,
  }) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onSmsQueued':
          await onSmsQueued();
          return;
        case 'onSms':
          final arg = Map<String, dynamic>.from(call.arguments as Map);
          await onSms(arg);
          return;
      }
    });
  }
}
