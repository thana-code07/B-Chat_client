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
    required this.onDeleteAccount,
  });

  final SessionUser user;
  final String token;
  final ChatApi api;
  final ChatConnection chat;
  final bool loggingOut;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  @override
  State<SignedInScreen> createState() => _SignedInScreenState();
}

class _SignedInScreenState extends State<SignedInScreen> {
  final List<_Dest> _stack = [_Dest.inbox()];
  late final StreamSubscription<ThreadMessage> _messages;
  late final StreamSubscription<PresenceUpdate> _presence;

  var _loading = true;
  var _loadingMore = false;
  var _loadGen = 0;
  String? _error;
  String? _nextCursor;
  List<Conversation> _conversations = const [];
  final Set<String> _countedMessageIds = {};
  Future<void> _reads = Future<void>.value();

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

  Future<void> _load({bool older = false}) async {
    if (older && (_loadingMore || _nextCursor == null)) return;
    final requestGen = older ? _loadGen : ++_loadGen;
    if (older) _loadingMore = true;
    try {
      final page = await widget.api.conversations(
        widget.token,
        before: older ? _nextCursor : null,
      );
      if (!mounted || requestGen != _loadGen) return;
      final openId = _stack.last.chat?.user.id;
      setState(() {
        if (older) {
          final seen = _conversations
              .map((conversation) => conversation.user.id)
              .toSet();
          _conversations = [
            ..._conversations,
            for (final conversation in page.conversations)
              if (seen.add(conversation.user.id)) conversation,
          ];
        } else {
          _conversations = [
            for (final conversation in page.conversations)
              conversation.user.id == openId
                  ? conversation.copyWith(unreadCount: 0)
                  : conversation,
          ];
        }
        _nextCursor = page.nextCursor;
        _loading = false;
        _error = null;
      });
      _watch();
    } on ChatException catch (error) {
      if (!mounted || requestGen != _loadGen || older) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } finally {
      _loadingMore = false;
    }
  }

  void _watch() {
    final ids = <String>[];
    final open = _stack.last.chat?.user.id;
    if (open != null) ids.add(open);
    for (final conversation in _conversations) {
      if (ids.length >= 50) break;
      if (ids.contains(conversation.user.id)) continue;
      ids.add(conversation.user.id);
    }
    widget.chat.watchPresence(ids);
  }

  void _onMessage(ThreadMessage message) {
    final me = widget.user.id;
    if (message.sender != me && message.receiver != me) return;
    final partnerId = message.sender == me ? message.receiver : message.sender;
    final fresh = _countedMessageIds.add(message.messageId);
    final viewing = _stack.last.chat?.user.id == partnerId;
    final incoming = message.sender == partnerId && message.status != 'read';
    if (viewing && incoming && fresh) {
      _reads = widget.chat.markRead(partnerId);
    }
    final index = _conversations.indexWhere(
      (conversation) => conversation.user.id == partnerId,
    );
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
      unreadCount: !fresh
          ? current.unreadCount
          : viewing
          ? 0
          : incoming
          ? current.unreadCount + 1
          : current.unreadCount,
    );
    setState(() {
      _conversations = [
        updated,
        ..._conversations.where(
          (conversation) => conversation.user.id != partnerId,
        ),
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
      _conversations = [
        for (final item in _conversations)
          item.user.id == conversation.user.id
              ? item.copyWith(unreadCount: 0)
              : item,
      ];
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
    _reads = widget.chat.markRead(conversation.user.id);
  }

  Future<void> _openUser(ChatUser user) async {
    final open = await widget.api.openConversation(widget.token, user.id);
    if (!mounted) return;
    setState(() {
      if (_stack.last.kind == _Kind.search) _stack.removeLast();
      _conversations = [
        for (final item in _conversations)
          item.user.id == user.id ? item.copyWith(unreadCount: 0) : item,
      ];
      _stack.add(_Dest.thread(open));
    });
    _watch();
    _reads = widget.chat.markRead(user.id);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account and messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) widget.onDeleteAccount();
  }

  void _back() {
    if (_stack.length <= 1) return;
    final leftThread = _stack.last.kind == _Kind.thread;
    setState(() => _stack.removeLast());
    _watch();
    if (!leftThread) {
      _load();
      return;
    }
    final reads = _reads;
    reads.whenComplete(() {
      if (mounted) _load();
    });
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
        onDeleteAccount: _confirmDelete,
        onNewChat: () => setState(() => _stack.add(_Dest.search())),
        onOpen: _openConversation,
        onLoadMore: _nextCursor == null ? null : () => _load(older: true),
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
