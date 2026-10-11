import 'dart:async';

import 'package:flutter/material.dart';

import '../data/chat_api.dart';
import '../theme/app_colors.dart';
import '../widgets/letter_avatar.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({
    super.key,
    required this.onBack,
    required this.onSearch,
    required this.onOpen,
  });

  final VoidCallback onBack;
  final Future<List<ChatUser>> Function(String query) onSearch;
  final Future<void> Function(ChatUser user) onOpen;

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  var _request = 0;
  var _searching = false;
  var _opening = false;
  var _searched = false;
  String? _error;
  List<ChatUser> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _error = null;
        _searching = false;
        _searched = false;
        _request += 1;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _run(query));
  }

  Future<void> _run(String query) async {
    final request = ++_request;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final users = await widget.onSearch(query);
      if (!mounted || request != _request) return;
      setState(() {
        _results = users;
        _searching = false;
        _searched = true;
      });
    } on ChatException catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _searching = false;
        _searched = true;
        _error = error.message;
      });
    }
  }

  Future<void> _open(ChatUser user) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await widget.onOpen(user);
    } on ChatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.chatInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        titleSpacing: 0,
        title: const Text(
          'New Chat',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.chatInk,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _query,
              autofocus: true,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: AppColors.button, width: 1.5),
                ),
              ),
            ),
          ),
          if (_searching) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _resultsBody()),
        ],
      ),
    );
  }

  Widget _resultsBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      );
    }
    if (_searched && _results.isEmpty && !_searching) {
      return const Center(
        child: Text(
          'No users found',
          style: TextStyle(color: AppColors.chatMuted, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final user = _results[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: LetterAvatar(
            username: user.username,
            background: AppColors.avatarFill,
            foreground: AppColors.avatarLetter,
            size: 44,
          ),
          title: Text(
            user.username,
            style: const TextStyle(
              color: AppColors.chatInk,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: _opening ? null : () => _open(user),
        );
      },
    );
  }
}
