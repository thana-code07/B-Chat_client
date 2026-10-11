import 'package:flutter/material.dart';

enum AuthMotion { none, rise, forward }

class AuthPage extends Page<void> {
  const AuthPage({required this.child, required this.motion, super.key});

  final Widget child;
  final AuthMotion motion;

  @override
  Route<void> createRoute(BuildContext context) => _AuthRoute(page: this);
}

class _AuthRoute extends PageRoute<void> {
  _AuthRoute({required AuthPage page}) : super(settings: page);

  AuthPage get _page => settings as AuthPage;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration =>
      _duration(const Duration(milliseconds: 420));

  @override
  Duration get reverseTransitionDuration =>
      _duration(const Duration(milliseconds: 360));

  Duration _duration(Duration full) {
    if (_page.motion == AuthMotion.none) return Duration.zero;
    final context = navigator?.context;
    if (context != null && MediaQuery.disableAnimationsOf(context)) {
      return Duration.zero;
    }
    return full;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: _page.child,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (_page.motion == AuthMotion.none ||
        MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    return _AuthMotion(
      animation: animation,
      motion: _page.motion,
      child: child,
    );
  }
}

class _AuthMotion extends StatefulWidget {
  const _AuthMotion({
    required this.animation,
    required this.motion,
    required this.child,
  });

  final Animation<double> animation;
  final AuthMotion motion;
  final Widget child;

  @override
  State<_AuthMotion> createState() => _AuthMotionState();
}

class _AuthMotionState extends State<_AuthMotion> {
  late final CurvedAnimation _move;
  late final CurvedAnimation _fade;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _move = CurvedAnimation(
      parent: widget.animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _fade = CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(0, 0.6, curve: Curves.easeOut),
      reverseCurve: const Interval(0.2, 1, curve: Curves.easeIn),
    );
    _offset = Tween<Offset>(
      begin: switch (widget.motion) {
        AuthMotion.rise => const Offset(0, 0.22),
        AuthMotion.forward => const Offset(0.28, 0),
        AuthMotion.none => Offset.zero,
      },
      end: Offset.zero,
    ).animate(_move);
  }

  @override
  void dispose() {
    _move.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SlideTransition(
        position: _offset,
        child: FadeTransition(opacity: _fade, child: widget.child),
      ),
    );
  }
}
