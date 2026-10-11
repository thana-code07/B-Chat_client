import 'dart:async';

import 'package:flutter/material.dart';

import '../data/auth_api.dart';
import '../data/chat_api.dart';
import '../data/chat_connection.dart';
import 'inbox_screen.dart';
import 'new_chat_screen.dart';
import 'thread_screen.dart';

enum _Kind { inbox, search, thread }

class _Dest {
  _Dest.inbox() : kind = _Kind.inbox, chat = null;
  _Dest.search() : kind = _Kind.search, chat = null;
  _Dest.thread(this.chat) : kind = _Kind.thread;

  final _Kind kind;
  final OpenChat? chat;
}

class SignedInScreen extends StatefulWidget {
  const SignedInScreen({
    super.key,
    required this.user,
    required this.token,
    required this.api,
    required this.chat,
    required this.loggingOut,
    required this.onLogout,
  });

  final SessionUser user;
  final String token;
  final ChatApi api;
  final ChatConnection chat;
  final bool loggingOut;
  final VoidCallback onLogout;

  @override
  State<SignedInScreen> createState() => _SignedInScreenState();
}

class _SignedInScreenState extends State<SignedInScreen> {
  final List<_Dest> _stack = [_Dest.inbox()];
  late final StreamSubscription<ThreadMessage> _messages;
  late final StreamSubscription<PresenceUpdate> _presence;

  var _loading = true;
  var _loadGen = 0;
  String? _error;
  List<Conversation> _conversations = const [];

  @override
  void initState() {
    super.initState();
    _messages = widget.chat.messages.listen(_onMessage);
    _presence = widget.chat.presence.listen(_onPresence);
    _load();
  }

  @override
  void dispose() {
    _messages.cancel();
    _presence.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final gen = ++_loadGen;
    try {
      final conversations = await widget.api.conversations(widget.token);
      if (!mounted || gen != _loadGen) return;
      setState(() {
        _conversations = conversations;
        _loading = false;
        _error = null;
      });
      _watch();
    } on ChatException catch (error) {
      if (!mounted || gen != _loadGen) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  void _watch() {
    final ids = _conversations.map((conversation) => conversation.user.id).toSet();
    final open = _stack.last.chat;
    if (open != null) ids.add(open.user.id);
    widget.chat.watchPresence(ids.take(50).toList());
  }

  void _onMessage(ThreadMessage message) {
    final me = widget.user.id;
    if (message.sender != me && message.receiver != me) return;
    final partnerId = message.sender == me ? message.receiver : message.sender;
    final index = _conversations.indexWhere((conversation) => conversation.user.id == partnerId);
    if (index < 0) {
      _load();
      return;
    }
    final current = _conversations[index];
    final updated = current.copyWith(
      lastMessage: LastMessage(
        message: message.message,
        createdAt: message.createdAt,
        status: message.status,
        sender: message.sender,
      ),
    );
    setState(() {
      _conversations = [
        updated,
        ..._conversations.where((conversation) => conversation.user.id != partnerId),
      ];
    });
  }

  void _onPresence(PresenceUpdate update) {
    if (!mounted) return;
    setState(() {
      _conversations = [
        for (final conversation in _conversations)
          conversation.user.id == update.userId
              ? conversation.copyWith(isOnline: update.isOnline)
              : conversation,
      ];
    });
  }

  void _openConversation(Conversation conversation) {
    setState(() {
      _stack.add(
        _Dest.thread(
          OpenChat(
            chatroomId: conversation.chatroomId,
            user: conversation.user,
            isOnline: conversation.isOnline,
          ),
        ),
      );
    });
    _watch();
  }

  Future<void> _openUser(ChatUser user) async {
    final open = await widget.api.openConversation(widget.token, user.id);
    if (!mounted) return;
    setState(() {
      if (_stack.last.kind == _Kind.search) _stack.removeLast();
      _stack.add(_Dest.thread(open));
    });
    _watch();
  }

  void _back() {
    if (_stack.length <= 1) return;
    setState(() => _stack.removeLast());
    _watch();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final dest = _stack.last;
    return switch (dest.kind) {
      _Kind.inbox => InboxScreen(
        conversations: _conversations,
        loading: _loading,
        error: _error,
        loggingOut: widget.loggingOut,
        onLogout: widget.onLogout,
        onNewChat: () => setState(() => _stack.add(_Dest.search())),
        onOpen: _openConversation,
        onRetry: () {
          _load();
        },
      ),
      _Kind.search => NewChatScreen(
        onBack: _back,
        onSearch: (query) => widget.api.searchUsers(widget.token, query),
        onOpen: _openUser,
      ),
      _Kind.thread => ThreadScreen(
        token: widget.token,
        selfId: widget.user.id,
        peer: dest.chat!,
        api: widget.api,
        chat: widget.chat,
        onBack: _back,
      ),
    };
  }
}
