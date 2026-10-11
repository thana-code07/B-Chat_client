import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.onBack,
    this.title,
  });

  final Widget child;
  final VoidCallback? onBack;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brand,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              child: onBack != null
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back'),
                      ),
                    )
                  : title == null
                  ? null
                  : Center(
                      child: Text(
                        title!,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
          ),
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class AccountSwitch extends StatelessWidget {
  const AccountSwitch({
    super.key,
    required this.prompt,
    required this.action,
    required this.onPressed,
  });

  final String prompt;
  final String action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt, style: const TextStyle(color: AppColors.muted)),
        TextButton(onPressed: onPressed, child: Text(action)),
      ],
    );
  }
}
