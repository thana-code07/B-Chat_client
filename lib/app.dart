import 'dart:async';

import 'package:flutter/material.dart';

import 'config/api_config.dart';
import 'data/auth_api.dart';
import 'data/chat_connection.dart';
import 'data/session_store.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_colors.dart';

enum _Gate { loading, welcome, login, register }

class BChatApp extends StatefulWidget {
  const BChatApp({
    super.key,
    this.sessionStore,
    this.authApi,
    this.chatConnection,
  });

  final SessionStore? sessionStore;
  final AuthApi? authApi;
  final ChatConnection? chatConnection;

  @override
  State<BChatApp> createState() => _BChatAppState();
}

class _BChatAppState extends State<BChatApp> {
  late final SessionStore _store = widget.sessionStore ?? SecureSessionStore();
  late final AuthApi _api = widget.authApi ?? AuthApi();
  late final ChatConnection _chat = widget.chatConnection ?? ChatConnection();
  late final StreamSubscription<SocketPhase> _phases;

  _Gate _gate = _Gate.loading;
  final List<_Gate> _stack = [_Gate.welcome];
  SessionUser? _user;
  SocketPhase _phase = SocketPhase.offline;
  var _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _phases = _chat.phases.listen((phase) {
      if (!mounted) return;
      setState(() => _phase = phase);
    });
    _restore();
  }

  @override
  void dispose() {
    _phases.cancel();
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
      _stack
        ..clear()
        ..add(_Gate.welcome);
      _gate = _Gate.welcome;
      _phase = SocketPhase.offline;
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

  Future<void> _enter(SessionUser user, String token) async {
    if (!mounted) return;
    setState(() {
      _user = user;
      _phase = SocketPhase.connecting;
    });
    try {
      await _chat.connect(apiBaseUrl: apiBaseUrl(), userId: user.id, token: token);
    } catch (_) {
      if (!mounted) return;
      setState(() => _phase = SocketPhase.offline);
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

  Future<String?> _register(String username, String email, String password) async {
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
    if (user != null) {
      return HomeScreen(
        username: user.username,
        phase: _phase,
        loggingOut: _loggingOut,
        onLogout: _logout,
      );
    }

    return switch (_gate) {
      _Gate.loading => const Scaffold(
        backgroundColor: AppColors.brand,
        body: Center(child: CircularProgressIndicator()),
      ),
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
