import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/chat_api.dart';
import '../data/chat_connection.dart';
import '../format/chat_time.dart';
import '../theme/app_colors.dart';
import '../widgets/chat_bubble.dart';

class ThreadScreen extends StatefulWidget {
  const ThreadScreen({
    super.key,
    required this.token,
    required this.selfId,
    required this.peer,
    required this.api,
    required this.chat,
    required this.onBack,
  });

  final String token;
  final String selfId;
  final OpenChat peer;
  final ChatApi api;
  final ChatConnection chat;
  final VoidCallback onBack;

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  final _random = Random();
  late final StreamSubscription<ThreadMessage> _messages;
  late final StreamSubscription<ThreadMessage> _statuses;
  late final StreamSubscription<PresenceUpdate> _presence;
  late final StreamSubscription<SocketPhase> _phases;

  Timer? _readDebounce;
  var _online = false;
  var _loading = true;
  var _sending = false;
  var _hasMore = false;
  var _page = 1;
  String? _error;
  final List<ThreadMessage> _history = [];

  @override
  void initState() {
    super.initState();
    _online = widget.peer.isOnline;
    _composer.addListener(() {
      if (mounted) setState(() {});
    });
    _messages = widget.chat.messages.listen(_onMessage);
    _statuses = widget.chat.statuses.listen(_onStatus);
    _presence = widget.chat.presence.listen((update) {
      if (!mounted || update.userId != widget.peer.user.id) return;
      setState(() => _online = update.isOnline);
    });
    _phases = widget.chat.phases.listen((phase) {
      if (phase == SocketPhase.connected) _scheduleRead();
    });
    _load();
  }

  @override
  void dispose() {
    _readDebounce?.cancel();
    _messages.cancel();
    _statuses.cancel();
    _presence.cancel();
    _phases.cancel();
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool _forThisChat(ThreadMessage message) {
    final peer = widget.peer.user.id;
    final me = widget.selfId;
    return (message.sender == me && message.receiver == peer) ||
        (message.sender == peer && message.receiver == me);
  }

  void _onMessage(ThreadMessage message) {
    if (!_forThisChat(message)) return;
    _upsert(message);
    if (message.sender == widget.peer.user.id) {
      _scheduleRead();
      _scrollToEnd();
    }
  }

  void _onStatus(ThreadMessage message) {
    if (!_forThisChat(message)) return;
    final index = _history.indexWhere((item) => item.messageId == message.messageId);
    if (index < 0 || !mounted) return;
    setState(() => _history[index] = _history[index].copyWith(status: message.status));
  }

  void _upsert(ThreadMessage message) {
    if (!mounted) return;
    final index = _history.indexWhere((item) => item.messageId == message.messageId);
    setState(() {
      if (index >= 0) {
        _history[index] = message;
      } else {
        _history.add(message);
      }
    });
  }

  Future<void> _load({bool older = false}) async {
    final before = older && _scroll.hasClients ? _scroll.position.maxScrollExtent : null;
    try {
      final page = await widget.api.messages(
        widget.token,
        widget.peer.user.id,
        page: older ? _page + 1 : 1,
      );
      if (!mounted) return;
      final chronological = page.messages.reversed.toList();
      setState(() {
        if (older) {
          _history.insertAll(0, chronological);
          _page = page.page;
        } else {
          _history
            ..clear()
            ..addAll(chronological);
          _page = 1;
        }
        _hasMore = page.page < page.totalPages;
        _loading = false;
        _error = null;
      });
      if (older && before != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scroll.hasClients) return;
          final delta = _scroll.position.maxScrollExtent - before;
          _scroll.jumpTo(_scroll.position.pixels + delta);
        });
      } else if (!older) {
        _scrollToEnd();
        _scheduleRead();
      }
    } on ChatException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _sending) return;
    final messageId = _messageId();
    final optimistic = ThreadMessage(
      chatroomId: widget.peer.chatroomId,
      messageId: messageId,
      sender: widget.selfId,
      receiver: widget.peer.user.id,
      message: text,
      status: 'sent',
      createdAt: DateTime.now(),
    );
    setState(() {
      _sending = true;
      _history.add(optimistic);
    });
    _composer.clear();
    _scrollToEnd();

    try {
      final saved = widget.chat.phase == SocketPhase.connected
          ? await widget.chat.sendMessage(
              chatroomId: widget.peer.chatroomId,
              receiver: widget.peer.user.id,
              messageId: messageId,
              message: text,
            )
          : await widget.api.sendMessage(
              token: widget.token,
              chatroomId: widget.peer.chatroomId,
              receiver: widget.peer.user.id,
              messageId: messageId,
              message: text,
            );
      if (!mounted) return;
      _upsert(saved);
    } on ChatException catch (error) {
      if (!mounted) return;
      setState(() => _history.removeWhere((item) => item.messageId == messageId));
      _composer.text = text;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scheduleRead() {
    _readDebounce?.cancel();
    _readDebounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      widget.chat.markRead(widget.peer.user.id);
    });
  }

  String _messageId() {
    final time = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final extra = _random.nextInt(0x7fffffff).toRadixString(16);
    return 'm$time$extra';
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSend = !_sending && _composer.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.inbox,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back, color: AppColors.chatInk),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.peer.user.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.chatInk,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_online)
                          const Text(
                            'Online',
                            style: TextStyle(color: AppColors.online, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _historyBody()),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composer,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Send',
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: canSend ? AppColors.send : AppColors.sendDisabled,
                        disabledBackgroundColor: AppColors.sendDisabled,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(48, 48),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: canSend ? _send : null,
                      child: const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyBody() {
    if (_loading && _history.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.chatInk));
    }
    if (_error != null && _history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
              const SizedBox(height: 12),
              TextButton(onPressed: () => _load(), child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    if (_history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No messages yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.chatMuted, fontSize: 15, height: 1.4),
              ),
              Text(
                'Send a message to start the conversation!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.chatMuted, fontSize: 15, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scroll,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _history.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (_hasMore && index == 0) {
          return TextButton(onPressed: () => _load(older: true), child: const Text('Earlier messages'));
        }
        final message = _history[_hasMore ? index - 1 : index];
        return ChatBubble(
          message: message.message,
          time: formatChatTime(message.createdAt),
          mine: message.sender == widget.selfId,
          status: message.status,
        );
      },
    );
  }
}
