import 'package:flutter/material.dart';

import '../data/chat_connection.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.username,
    required this.phase,
    required this.onLogout,
    required this.loggingOut,
  });

  final String username;
  final SocketPhase phase;
  final VoidCallback onLogout;
  final bool loggingOut;

  @override
  Widget build(BuildContext context) {
    final status = switch (phase) {
      SocketPhase.connecting => ('Connecting', Icons.cloud_queue_outlined),
      SocketPhase.connected => ('Connected', Icons.cloud_done_outlined),
      SocketPhase.offline => ('Offline', Icons.cloud_off_outlined),
    };

    return AuthScaffold(
      title: 'Chat Application',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        children: [
          Text('Hello, $username', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'You are signed in.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 32),
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                Icon(status.$2, color: AppColors.link),
                const SizedBox(width: 12),
                Text(status.$1, style: const TextStyle(fontSize: 16, color: AppColors.ink)),
                if (phase == SocketPhase.connecting) ...[
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: loggingOut ? null : onLogout,
            child: Text(loggingOut ? 'Signing out' : 'Logout'),
          ),
        ],
      ),
    );
  }
}
