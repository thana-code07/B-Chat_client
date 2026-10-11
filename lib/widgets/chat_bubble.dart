import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.time,
    required this.mine,
    required this.status,
  });

  final String message;
  final String time;
  final bool mine;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: mine ? AppColors.outgoing : AppColors.incoming,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.chatInk,
                      fontSize: 16,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      color: AppColors.chatMuted,
                      fontSize: 11,
                    ),
                  ),
                  if (mine && status == 'delivered') ...[
                    const SizedBox(width: 4),
                    Semantics(
                      label: 'Delivered',
                      child: const Icon(
                        Icons.done_all,
                        size: 16,
                        color: AppColors.deliveredReceipt,
                      ),
                    ),
                  ],
                  if (mine && status == 'read') ...[
                    const SizedBox(width: 4),
                    Semantics(
                      label: 'Read',
                      child: const Icon(
                        Icons.done_all,
                        size: 16,
                        color: AppColors.readReceipt,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
