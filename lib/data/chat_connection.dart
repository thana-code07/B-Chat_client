import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import 'chat_api.dart';

enum SocketPhase { connecting, connected, offline }

class PresenceUpdate {
  const PresenceUpdate({required this.userId, required this.isOnline});

  final String userId;
  final bool isOnline;
}

class ChatConnection {
  final _phases = StreamController<SocketPhase>.broadcast();
  final _messages = StreamController<ThreadMessage>.broadcast();
  final _statuses = StreamController<ThreadMessage>.broadcast();
  final _presence = StreamController<PresenceUpdate>.broadcast();

  SocketPhase phase = SocketPhase.offline;
  socket_io.Socket? _socket;
  List<String> _watchIds = const [];

  Stream<SocketPhase> get phases => _phases.stream;
  Stream<ThreadMessage> get messages => _messages.stream;
  Stream<ThreadMessage> get statuses => _statuses.stream;
  Stream<PresenceUpdate> get presence => _presence.stream;

  Future<void> connect({
    required String apiBaseUrl,
    required String userId,
    required String token,
  }) async {
    await _closeSocket();
    _setPhase(SocketPhase.connecting);

    final base = apiBaseUrl.endsWith('/') ? apiBaseUrl.substring(0, apiBaseUrl.length - 1) : apiBaseUrl;
    final socket = socket_io.io(
      base,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNew()
          .enableReconnection()
          .setReconnectionAttempts(8)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setAuth({'token': token})
          .setQuery({'token': token})
          .build(),
    );
    _socket = socket;

    socket.onConnect((_) {
      if (!identical(_socket, socket)) return;
      _setPhase(SocketPhase.connected);
      _emitWatch();
    });
    socket.onDisconnect((_) {
      if (!identical(_socket, socket)) return;
      _setPhase(SocketPhase.offline);
    });
    socket.onConnectError((_) {
      if (!identical(_socket, socket)) return;
      _setPhase(SocketPhase.offline);
    });
    socket.on('message:new', (data) {
      if (!identical(_socket, socket)) return;
      final message = _readMessage(data);
      if (message != null && !_messages.isClosed) _messages.add(message);
    });
    socket.on('message:status', (data) {
      if (!identical(_socket, socket)) return;
      final message = _readMessage(data);
      if (message != null && !_statuses.isClosed) _statuses.add(message);
    });
    socket.on('presence:update', (data) {
      if (!identical(_socket, socket)) return;
      final update = _readPresence(data);
      if (update != null && !_presence.isClosed) _presence.add(update);
    });
  }

  Future<void> disconnect() async {
    _watchIds = const [];
    await _closeSocket();
    _setPhase(SocketPhase.offline);
  }

  Future<void> watchPresence(List<String> userIds) async {
    _watchIds = userIds.take(50).toList();
    _emitWatch();
  }

  Future<ThreadMessage> sendMessage({
    required String chatroomId,
    required String receiver,
    required String messageId,
    required String message,
  }) async {
    final body = await _ack('message:send', {
      'chatroomId': chatroomId,
      'receiver': receiver,
      'messageId': messageId,
      'message': message,
    });
    final payload = body['message'];
    if (payload is! Map) {
      throw ChatException('Something went wrong. Try again.');
    }
    final saved = ThreadMessage.fromJson(Map<String, dynamic>.from(payload));
    if (!_messages.isClosed) _messages.add(saved);
    return saved;
  }

  Future<void> markRead(String userId) async {
    try {
      await _ack('message:read', {'userId': userId});
    } catch (_) {
      // The next time this chat is open, unread messages are marked again.
    }
  }

  void _emitWatch() {
    final socket = _socket;
    if (socket == null || !socket.connected) return;
    socket.emitWithAck('presence:watch', {
      'userIds': _watchIds,
    }, ack: (data) {
      if (data is! Map || data['users'] is! List) return;
      for (final item in data['users'] as List) {
        final update = _readPresence(item);
        if (update != null && !_presence.isClosed) _presence.add(update);
      }
    });
  }

  Future<Map<String, dynamic>> _ack(String event, Map<String, dynamic> payload) {
    final socket = _socket;
    if (socket == null || !socket.connected) {
      throw ChatException('Cannot reach the server. Check that it is running.');
    }

    final completer = Completer<Map<String, dynamic>>();
    final timer = Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.completeError(ChatException('Cannot reach the server. Check that it is running.'));
      }
    });
    socket.emitWithAck(event, payload, ack: (data) {
      timer.cancel();
      if (completer.isCompleted) return;
      if (data is Map && data['error'] is Map) {
        final message = (data['error'] as Map)['message'];
        completer.completeError(
          ChatException(message is String && message.isNotEmpty ? message : 'Something went wrong. Try again.'),
        );
        return;
      }
      if (data is Map) {
        completer.complete(Map<String, dynamic>.from(data));
        return;
      }
      completer.completeError(ChatException('Something went wrong. Try again.'));
    });
    return completer.future;
  }

  ThreadMessage? _readMessage(dynamic data) {
    if (data is! Map || data['message'] is! Map) return null;
    try {
      return ThreadMessage.fromJson(Map<String, dynamic>.from(data['message'] as Map));
    } catch (_) {
      return null;
    }
  }

  PresenceUpdate? _readPresence(dynamic data) {
    if (data is! Map) return null;
    final userId = data['userId'];
    final online = data['isOnline'];
    if (userId is! String || online is! bool) return null;
    return PresenceUpdate(userId: userId, isOnline: online);
  }

  Future<void> _closeSocket() async {
    final socket = _socket;
    _socket = null;
    if (socket == null) return;
    socket.disconnect();
    socket.dispose();
    socket_io.cache.clear();
  }

  void _setPhase(SocketPhase next) {
    phase = next;
    if (!_phases.isClosed) _phases.add(next);
  }

  void dispose() {
    _closeSocket();
    _phases.close();
    _messages.close();
    _statuses.close();
    _presence.close();
  }
}
