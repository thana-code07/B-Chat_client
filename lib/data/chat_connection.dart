import 'dart:async';

import 'package:chat_plugin/chat_plugin.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

enum SocketPhase { connecting, connected, offline }

class ChatConnection {
  final _phases = StreamController<SocketPhase>.broadcast();
  SocketPhase phase = SocketPhase.offline;

  Stream<SocketPhase> get phases => _phases.stream;

  static const _statusListener = 'session_connection';
  static const _errorListener = 'session_connection_error';

  /// chat_plugin 1.0.0 opens Socket.IO from [ChatConfig.apiUrl] and does not
  /// attach the JWT. The token rides in the query so the server can still
  /// authenticate the handshake.
  Future<void> connect({
    required String apiBaseUrl,
    required String userId,
    required String token,
  }) async {
    _setPhase(SocketPhase.connecting);

    final base = apiBaseUrl.endsWith('/') ? apiBaseUrl.substring(0, apiBaseUrl.length - 1) : apiBaseUrl;
    final socketUrl = '$base/?token=${Uri.encodeQueryComponent(token)}';

    ChatService.instance.setDebugMode(false);
    await ChatPlugin.initialize(
      config: ChatConfig(
        apiUrl: socketUrl,
        userId: userId,
        token: token,
        enableTypingIndicators: false,
        enableReadReceipts: false,
        enableOnlineStatus: false,
        autoMarkAsRead: false,
        debugMode: false,
      ),
    );

    ChatService.instance.removeEventListener(
      ChatEventType.connectionStatusChanged,
      _statusListener,
    );
    ChatService.instance.addEventListener(
      ChatEventType.connectionStatusChanged,
      _statusListener,
      (dynamic connected) {
        _setPhase(connected == true ? SocketPhase.connected : SocketPhase.offline);
      },
    );
    ChatService.instance.removeEventListener(ChatEventType.error, _errorListener);
    ChatService.instance.addEventListener(ChatEventType.error, _errorListener, (_) {
      _setPhase(SocketPhase.offline);
    });

    await ChatService.instance.initialize();
  }

  Future<void> disconnect() async {
    ChatService.instance.removeEventListener(
      ChatEventType.connectionStatusChanged,
      _statusListener,
    );
    ChatService.instance.removeEventListener(ChatEventType.error, _errorListener);
    ChatService.instance.fullDisconnect();
    socket_io.cache.clear();
    _setPhase(SocketPhase.offline);
  }

  void _setPhase(SocketPhase next) {
    phase = next;
    if (!_phases.isClosed) _phases.add(next);
  }

  void dispose() {
    _phases.close();
  }
}
