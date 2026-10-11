import 'package:dio/dio.dart';

import '../config/api_config.dart';

class ChatException implements Exception {
  ChatException(this.message);
  final String message;
}

class ChatUser {
  const ChatUser({required this.id, required this.username});

  final String id;
  final String username;

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] as String,
      username: json['username'] as String,
    );
  }
}

class ThreadMessage {
  const ThreadMessage({
    required this.chatroomId,
    required this.messageId,
    required this.sender,
    required this.receiver,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  final String chatroomId;
  final String messageId;
  final String sender;
  final String receiver;
  final String message;
  final String status;
  final DateTime createdAt;

  factory ThreadMessage.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'];
    return ThreadMessage(
      chatroomId: json['chatroomId'] as String,
      messageId: json['messageId'] as String,
      sender: json['sender'] as String,
      receiver: json['receiver'] as String,
      message: json['message'] as String,
      status: json['status'] as String? ?? 'sent',
      createdAt: created is String ? DateTime.parse(created) : DateTime.now(),
    );
  }

  ThreadMessage copyWith({String? status}) {
    return ThreadMessage(
      chatroomId: chatroomId,
      messageId: messageId,
      sender: sender,
      receiver: receiver,
      message: message,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

class LastMessage {
  const LastMessage({
    required this.message,
    required this.createdAt,
    required this.status,
    required this.sender,
  });

  final String message;
  final DateTime createdAt;
  final String status;
  final String sender;

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'];
    return LastMessage(
      message: json['message'] as String,
      createdAt: created is String ? DateTime.parse(created) : DateTime.now(),
      status: json['status'] as String? ?? 'sent',
      sender: json['sender'] as String,
    );
  }
}

class Conversation {
  const Conversation({
    required this.chatroomId,
    required this.user,
    required this.isOnline,
    required this.lastMessage,
    this.unreadCount = 0,
  });

  final String chatroomId;
  final ChatUser user;
  final bool isOnline;
  final LastMessage lastMessage;
  final int unreadCount;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final unread = json['unreadCount'];
    return Conversation(
      chatroomId: json['chatroomId'] as String,
      user: ChatUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
      isOnline: json['isOnline'] == true,
      lastMessage: LastMessage.fromJson(
        Map<String, dynamic>.from(json['lastMessage'] as Map),
      ),
      unreadCount: unread is num ? unread.toInt() : 0,
    );
  }

  Conversation copyWith({
    bool? isOnline,
    LastMessage? lastMessage,
    int? unreadCount,
  }) {
    return Conversation(
      chatroomId: chatroomId,
      user: user,
      isOnline: isOnline ?? this.isOnline,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class OpenChat {
  const OpenChat({
    required this.chatroomId,
    required this.user,
    required this.isOnline,
  });

  final String chatroomId;
  final ChatUser user;
  final bool isOnline;
}

class MessagePage {
  const MessagePage({
    required this.messages,
    required this.page,
    required this.totalPages,
  });

  final List<ThreadMessage> messages;
  final int page;
  final int totalPages;
}

class ChatApi {
  ChatApi({Dio? dio, String? baseUrl})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl ?? apiBaseUrl(),
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: const {'Accept': 'application/json'},
            ),
          );

  final Dio _dio;

  Future<List<Conversation>> conversations(String token) async {
    final response = await _send(
      () => _dio.get('/api/conversations', options: _bearer(token)),
    );
    final body = Map<String, dynamic>.from(response.data as Map);
    return (body['conversations'] as List)
        .map(
          (item) =>
              Conversation.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<ChatUser>> searchUsers(String token, String query) async {
    final response = await _send(
      () => _dio.get(
        '/api/users/search',
        queryParameters: {'q': query},
        options: _bearer(token),
      ),
    );
    final body = Map<String, dynamic>.from(response.data as Map);
    return (body['users'] as List)
        .map(
          (item) => ChatUser.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<OpenChat> openConversation(String token, String userId) async {
    final response = await _send(
      () =>
          _dio.get('/api/conversations/with/$userId', options: _bearer(token)),
    );
    final body = Map<String, dynamic>.from(response.data as Map);
    return OpenChat(
      chatroomId: body['chatroomId'] as String,
      user: ChatUser.fromJson(Map<String, dynamic>.from(body['user'] as Map)),
      isOnline: body['isOnline'] == true,
    );
  }

  Future<MessagePage> messages(
    String token,
    String userId, {
    int page = 1,
  }) async {
    final response = await _send(
      () => _dio.get(
        '/api/conversations/with/$userId/messages',
        queryParameters: {'page': page, 'pageSize': 20},
        options: _bearer(token),
      ),
    );
    final body = Map<String, dynamic>.from(response.data as Map);
    final pagination = Map<String, dynamic>.from(body['pagination'] as Map);
    return MessagePage(
      messages: (body['data'] as List)
          .map(
            (item) =>
                ThreadMessage.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      page: (pagination['page'] as num).toInt(),
      totalPages: (pagination['totalPages'] as num).toInt(),
    );
  }

  Future<ThreadMessage> sendMessage({
    required String token,
    required String chatroomId,
    required String receiver,
    required String messageId,
    required String message,
  }) async {
    final response = await _send(
      () => _dio.post(
        '/api/messages',
        data: {
          'chatroomId': chatroomId,
          'receiver': receiver,
          'messageId': messageId,
          'message': message,
        },
        options: _bearer(token),
      ),
    );
    final body = Map<String, dynamic>.from(response.data as Map);
    return ThreadMessage.fromJson(
      Map<String, dynamic>.from(body['message'] as Map),
    );
  }

  Options _bearer(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<Response<dynamic>> _send(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw ChatException(_message(error));
    }
  }

  String _message(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final body = data['error'];
      if (body is Map &&
          body['message'] is String &&
          (body['message'] as String).isNotEmpty) {
        return body['message'] as String;
      }
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. Check that it is running.';
      default:
        return 'Something went wrong. Try again.';
    }
  }
}
