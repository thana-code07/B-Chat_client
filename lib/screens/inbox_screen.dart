import 'package:flutter/material.dart';

import '../data/chat_api.dart';
import '../format/chat_time.dart';
import '../theme/app_colors.dart';
import '../widgets/letter_avatar.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({
    super.key,
    required this.conversations,
    required this.loading,
    required this.error,
    required this.loggingOut,
    required this.onLogout,
    required this.onNewChat,
    required this.onOpen,
    required this.onRetry,
  });

  final List<Conversation> conversations;
  final bool loading;
  final String? error;
  final bool loggingOut;
  final VoidCallback onLogout;
  final VoidCallback onNewChat;
  final ValueChanged<Conversation> onOpen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final online = conversations.where((conversation) => conversation.isOnline).toList();

    return Scaffold(
      backgroundColor: AppColors.inbox,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Direct Messages',
                      style: TextStyle(
                        color: AppColors.chatInk,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'New chat',
                    onPressed: onNewChat,
                    icon: const Icon(Icons.person_outline, color: AppColors.chatInk),
                  ),
                  IconButton(
                    tooltip: 'Logout',
                    onPressed: loggingOut ? null : onLogout,
                    icon: const Icon(Icons.logout, color: AppColors.chatInk),
                  ),
                ],
              ),
            ),
            if (online.isNotEmpty)
              SizedBox(
                height: 108,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  itemCount: online.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final conversation = online[index];
                    return Semantics(
                      button: true,
                      label: '${conversation.user.username}, online',
                      excludeSemantics: true,
                      child: InkWell(
                        onTap: () => onOpen(conversation),
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 76,
                          child: Column(
                            children: [
                              LetterAvatar(
                                username: conversation.user.username,
                                background: AppColors.avatarFill,
                                foreground: AppColors.avatarLetter,
                                size: 56,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                conversation.user.username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.chatMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                'Chat Room',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.chatMuted, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (loading && conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.chatInk));
    }
    if (error != null && conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    if (conversations.isEmpty) {
      return const Center(
        child: Text('No conversations yet', style: TextStyle(color: AppColors.chatMuted, fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        final time = formatChatTime(conversation.lastMessage.createdAt);
        return Semantics(
          button: true,
          label: '${conversation.user.username}, ${conversation.lastMessage.message}, $time',
          excludeSemantics: true,
          child: InkWell(
            onTap: () => onOpen(conversation),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  LetterAvatar(
                    username: conversation.user.username,
                    background: AppColors.chatAvatar,
                    foreground: Colors.white,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                conversation.user.username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.chatInk,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(time, style: const TextStyle(color: AppColors.chatMuted, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          conversation.lastMessage.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.chatMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
