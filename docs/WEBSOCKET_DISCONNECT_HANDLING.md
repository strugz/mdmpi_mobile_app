# WebSocket Disconnect Handling

The mobile/desktop client can lose network, background, hot-reload, or dispose
feature controllers while a WebSocket is active. The Flutter client now closes
intentional disconnects with `goingAway`, waits for `WebSocketChannel.ready`
before marking a socket connected, and prevents overlapping reconnect attempts.

The ASP.NET WebSocket endpoint should still treat abrupt client disconnects as
normal connection termination. In the server connection handler, especially
around `ReceiveAsync` loops such as `ReceiveMessagesAsync`, catch and downgrade
expected disconnects:

- `WebSocketException`
- `OperationCanceledException`
- receive results where `CloseStatus == null`

The message `The remote party closed the WebSocket connection without completing
the close handshake` usually means the client or network disappeared before the
closing frame exchange finished. Log it as a debug/info disconnect event and
clean up connection state instead of surfacing it as an unhandled application
exception.
