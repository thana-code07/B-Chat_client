import 'package:flutter/material.dart';

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
                child: Row(
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
