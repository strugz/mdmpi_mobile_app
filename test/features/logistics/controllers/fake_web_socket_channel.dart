import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Hand-rolled fake channel shared by the WebSocket controller tests.
class FakeWebSocketChannel implements WebSocketChannel {
  FakeWebSocketChannel({Future<void>? ready}) : ready = ready ?? Future.value();

  final StreamController<dynamic> _streamController =
      StreamController<dynamic>();
  final FakeWebSocketSink _sink = FakeWebSocketSink();

  @override
  final Future<void> ready;

  @override
  String? get protocol => null;

  @override
  int? closeCode;

  @override
  String? closeReason;

  @override
  Stream get stream => _streamController.stream;

  @override
  WebSocketSink get sink => _sink;

  int get closeCount => _sink.closeCount;

  List<dynamic> get sentMessages => _sink.sentMessages;

  void addIncoming(dynamic data) => _streamController.add(data);

  void addError(Object error) => _streamController.addError(error);

  Future<void> closeIncoming([int? code, String? reason]) {
    closeCode = code;
    closeReason = reason;
    return _streamController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeWebSocketSink implements WebSocketSink {
  final List<dynamic> sentMessages = [];
  int closeCount = 0;
  int? lastCloseCode;
  String? lastCloseReason;
  final Completer<void> _done = Completer<void>();

  @override
  Future<void> get done => _done.future;

  @override
  void add(dynamic event) {
    sentMessages.add(event);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    if (!_done.isCompleted) _done.completeError(error, stackTrace);
  }

  @override
  Future<void> addStream(Stream stream) async {
    await for (final event in stream) {
      add(event);
    }
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    closeCount += 1;
    lastCloseCode = closeCode;
    lastCloseReason = closeReason;
    if (!_done.isCompleted) _done.complete();
  }
}
