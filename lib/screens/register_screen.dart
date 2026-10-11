import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../validation/credentials.dart';
import '../widgets/auth_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.onBack,
    required this.onLogin,
    required this.onSubmit,
  });

  final VoidCallback onBack;
  final VoidCallback onLogin;
  final Future<String?> Function(String username, String email, String password) onSubmit;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _obscure = true;
  var _submitting = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final message = await widget.onSubmit(_username.text, _email.text, _password.text);
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
            Text('Create Account', style: Theme.of(context).textTheme.titleLarge),
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
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) => validateEmail(value ?? ''),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
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
                child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
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
                  : const Text('Register Now'),
            ),
            const SizedBox(height: 16),
            AccountSwitch(
              prompt: 'Already have an account?',
              action: 'Login',
              onPressed: _submitting ? null : widget.onLogin,
            ),
          ],
        ),
      ),
    );
  }
}
