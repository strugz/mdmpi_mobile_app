import 'package:web_socket_channel/web_socket_channel.dart';

enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  closing,
}

typedef WebSocketChannelFactory = WebSocketChannel Function(Uri uri);

class WebSocketConnectionConfig {
  WebSocketConnectionConfig._();

  static final Uri endpoint = Uri.parse(
    'wss://inventory.mdmpi.com.ph/api2/ws?apiKey=mdmpiIMSmdmpiIMSmdmpiIMS',
  );

  static const Duration reconnectDelay = Duration(seconds: 5);

  static WebSocketChannel connect(Uri uri) => WebSocketChannel.connect(uri);
}
