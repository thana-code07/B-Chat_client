import 'package:flutter/material.dart';

import '../demo/demo_accounts.dart';
import '../theme/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onLogin,
    required this.onRegister,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brand,
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: Center(
                      child: Icon(
                        Icons.chat_bubble_outline,
                        size: 40,
                        color: AppColors.link,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'B-Chat',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Demo accounts',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _DemoHeader(),
                    for (final account in demoAccounts)
                      _DemoAccountRow(account: account),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in as each account in two windows to chat.',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: onLogin,
                            child: const Text('Login'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onRegister,
                            child: const FittedBox(child: Text('Register Now')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _caption = TextStyle(fontSize: 12, color: AppColors.muted);
const _value = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: AppColors.ink,
);

class _DemoHeader extends StatelessWidget {
  const _DemoHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Text('Username', style: _caption)),
        Expanded(child: Text('Password', style: _caption)),
      ],
    );
  }
}

class _DemoAccountRow extends StatelessWidget {
  const _DemoAccountRow({required this.account});

  final DemoAccount account;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${account.username}, password ${account.password}',
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Expanded(
              child: SelectableText(account.username, style: _value),
            ),
            Expanded(
              child: SelectableText(account.password, style: _value),
            ),
          ],
        ),
      ),
    );
  }
}
