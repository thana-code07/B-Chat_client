import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../validation/credentials.dart';
import '../widgets/auth_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onBack,
    required this.onRegister,
    required this.onSubmit,
  });

  final VoidCallback onBack;
  final VoidCallback onRegister;
  final Future<String?> Function(String username, String password) onSubmit;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  var _obscure = true;
  var _submitting = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final message = await widget.onSubmit(_username.text, _password.text);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      onBack: _submitting ? null : widget.onBack,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            Text('Hello', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Sign into your Account',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _username,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(labelText: 'Username'),
              validator: (value) => validateUsername(value ?? ''),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
              validator: (value) => validatePassword(value ?? ''),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Login'),
            ),
            const SizedBox(height: 16),
            AccountSwitch(
              prompt: "Don't have an account?",
              action: 'Register Now',
              onPressed: _submitting ? null : widget.onRegister,
            ),
          ],
        ),
      ),
    );
  }
}
