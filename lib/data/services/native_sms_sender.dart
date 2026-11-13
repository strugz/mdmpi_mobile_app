import 'package:another_telephony/telephony.dart';
import 'package:flutter/services.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';

/// Sends an SMS through the app's own "mdmpi/sms" channel (MainActivity).
///
/// another_telephony reports SENT for every send callback without reading
/// Android's result code, so a send the radio refused (no load, no service,
/// airplane mode, Android's SMS limit) still read as sent. This channel
/// reports SENT only when every part came back RESULT_OK, and otherwise
/// passes SENT with an [error] saying why.
class NativeSmsSender {
  NativeSmsSender._();

  static const _channel = MethodChannel('mdmpi/sms');
  static final Map<String, void Function(SendStatus, {String? error})>
      _listeners = {};
  static bool _handlerSet = false;
  static int _seq = 0;

  static Future<void> send(String to, String message,
      void Function(SendStatus status, {String? error}) onStatus) async {
    if (!_handlerSet) {
      _channel.setMethodCallHandler(_onCall);
      _handlerSet = true;
    }
    final id = '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';
    _listeners[id] = onStatus;
    try {
      await _channel.invokeMethod<void>(
          'send', {'id': id, 'to': to, 'message': message});
    } catch (_) {
      _listeners.remove(id);
      rethrow;
    }
  }

  static Future<void> _onCall(MethodCall call) async {
    if (call.method != 'sent') return;
    final args = (call.arguments as Map<Object?, Object?>?) ?? const {};
    final listener = _listeners.remove(args['id']);
    if (listener == null) return;
    if (args['ok'] == true) {
      listener(SendStatus.SENT);
      return;
    }
    final error = failureReason(
        args['resultCode'] as int? ?? -1, args['errorCode'] as int?);
    logDebug('NativeSmsSender: $error');
    listener(SendStatus.SENT, error: error);
  }

  /// Android's SmsManager.RESULT_ERROR_* codes in words for the Outbox.
  static String failureReason(int resultCode, [int? errorCode]) {
    final why = switch (resultCode) {
      1 => 'The network refused the SMS. Check the SIM load or balance '
          'and the signal',
      2 => 'The phone radio is off (airplane mode?)',
      3 => 'The phone could not build the SMS',
      4 => 'No mobile service',
      5 => "Android's SMS limit was reached for this app",
      6 => 'The SIM only allows fixed dialing numbers',
      7 || 8 => 'Android blocked sending to this number',
      _ => 'The phone could not send the SMS (code $resultCode)',
    };
    return errorCode == null ? '$why.' : '$why (error $errorCode).';
  }
}
