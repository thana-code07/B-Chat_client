import 'package:flutter/material.dart';

import 'config/api_config.dart';
import 'data/auth_api.dart';
import 'data/chat_api.dart';
import 'data/chat_connection.dart';
import 'data/session_store.dart';
import 'navigation/auth_page.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/signed_in_screen.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_colors.dart';

enum _Gate { loading, welcome, login, register }

class BChatApp extends StatefulWidget {
  const BChatApp({
    super.key,
    this.sessionStore,
    this.authApi,
    this.chatConnection,
    this.chatApi,
  });

  final SessionStore? sessionStore;
  final AuthApi? authApi;
  final ChatConnection? chatConnection;
  final ChatApi? chatApi;

  @override
  State<BChatApp> createState() => _BChatAppState();
}

class _BChatAppState extends State<BChatApp> {
  late final SessionStore _store = widget.sessionStore ?? SecureSessionStore();
  late final AuthApi _api = widget.authApi ?? AuthApi();
  late final ChatConnection _chat = widget.chatConnection ?? ChatConnection();
  late final ChatApi _chatApi = widget.chatApi ?? ChatApi();

  _Gate _gate = _Gate.loading;
  final List<_Gate> _stack = [_Gate.welcome];
  SessionUser? _user;
  String? _token;
  var _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _chat.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    try {
      final token = await _store.readToken();
      if (token == null || token.isEmpty) {
        _showWelcome();
        return;
      }
      final user = await _api.me(token);
      await _enter(user, token);
    } catch (_) {
      await _store.clear();
      _showWelcome();
    }
  }

  void _showWelcome() {
    if (!mounted) return;
    setState(() {
      _user = null;
      _token = null;
      _stack
        ..clear()
        ..add(_Gate.welcome);
      _gate = _Gate.welcome;
    });
  }

  void _open(_Gate gate) {
    setState(() {
      if (_stack.length > 1 && _stack[_stack.length - 2] == gate) {
        _stack.removeLast();
      } else {
        _stack.add(gate);
      }
      _gate = _stack.last;
    });
  }

  void _back() {
    setState(() {
      if (_stack.length > 1) _stack.removeLast();
      _gate = _stack.last;
    });
  }

  void _onDidRemovePage(Page<Object?> page) {
    if (!mounted || _stack.length < 2) return;
    if (page.key != ValueKey<_Gate>(_stack.last)) return;
    _back();
  }

  AuthMotion _enterMotion(_Gate? from, _Gate to) {
    if (from == null) return AuthMotion.none;
    final betweenForms =
        (from == _Gate.login && to == _Gate.register) ||
        (from == _Gate.register && to == _Gate.login);
    if (betweenForms) return AuthMotion.forward;
    return AuthMotion.rise;
  }

  Future<void> _enter(SessionUser user, String token) async {
    if (!mounted) return;
    setState(() {
      _user = user;
      _token = token;
    });
    try {
      await _chat.connect(
        apiBaseUrl: apiBaseUrl(),
        userId: user.id,
        token: token,
      );
    } catch (_) {
      // The inbox still loads over HTTP. Live updates resume when the socket connects.
    }
  }

  Future<String?> _login(String username, String password) async {
    try {
      final session = await _api.login(username: username, password: password);
      await _store.writeToken(session.accessToken);
      await _enter(session.user, session.accessToken);
      return null;
    } on AuthException catch (error) {
      return error.message;
    }
  }

  Future<String?> _register(
    String username,
    String email,
    String password,
  ) async {
    try {
      final session = await _api.register(
        username: username,
        email: email,
        password: password,
      );
      await _store.writeToken(session.accessToken);
      await _enter(session.user, session.accessToken);
      return null;
    } on AuthException catch (error) {
      return error.message;
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      final token = await _store.readToken();
      if (token != null && token.isNotEmpty) {
        try {
          await _api.logout(token);
        } catch (_) {
          // Local sign-out still continues if the server is unreachable.
        }
      }
      await _chat.disconnect();
      await _store.clear();
    } finally {
      if (mounted) {
        setState(() => _loggingOut = false);
        _showWelcome();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Application',
      theme: buildAppTheme(),
      home: ColoredBox(
        color: AppColors.brand,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _home(),
          ),
        ),
      ),
    );
  }

  Widget _home() {
    final user = _user;
    final token = _token;
    if (user != null && token != null) {
      return SignedInScreen(
        user: user,
        token: token,
        api: _chatApi,
        chat: _chat,
        loggingOut: _loggingOut,
        onLogout: _logout,
      );
    }

    if (_gate == _Gate.loading) {
      return const Scaffold(
        backgroundColor: AppColors.brand,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ClipRect(
      child: NavigatorPopHandler(
        onPopWithResult: (_) => _back(),
        child: Navigator(
          pages: [
            for (var i = 0; i < _stack.length; i++)
              AuthPage(
                key: ValueKey<_Gate>(_stack[i]),
                motion: _enterMotion(i == 0 ? null : _stack[i - 1], _stack[i]),
                child: _gatePage(_stack[i]),
              ),
          ],
          onDidRemovePage: _onDidRemovePage,
        ),
      ),
    );
  }

  Widget _gatePage(_Gate gate) {
    return switch (gate) {
      _Gate.loading => const SizedBox.shrink(),
      _Gate.welcome => WelcomeScreen(
        onLogin: () => _open(_Gate.login),
        onRegister: () => _open(_Gate.register),
      ),
      _Gate.login => LoginScreen(
        onBack: _back,
        onRegister: () => _open(_Gate.register),
        onSubmit: _login,
      ),
      _Gate.register => RegisterScreen(
        onBack: _back,
        onLogin: () => _open(_Gate.login),
        onSubmit: _register,
      ),
    };
  }
}
