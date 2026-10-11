import 'package:client/app.dart';
import 'package:client/data/auth_api.dart';
import 'package:client/data/chat_connection.dart';
import 'package:client/data/session_store.dart';
import 'package:client/screens/login_screen.dart';
import 'package:client/screens/register_screen.dart';
import 'package:client/theme/app_colors.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _RestoringApi extends AuthApi {
  _RestoringApi() : super(dio: Dio(BaseOptions(baseUrl: 'http://localhost')));

  @override
  Future<SessionUser> me(String token) async {
    return const SessionUser(id: 'user-1', username: 'ada');
  }
}

class _QuietChat extends ChatConnection {
  @override
  Future<void> connect({
    required String apiBaseUrl,
    required String userId,
    required String token,
  }) async {}
}

void main() {
  testWidgets('welcome offers login and register', (tester) async {
    await tester.pumpWidget(BChatApp(sessionStore: MemorySessionStore()));
    await tester.pump();

    expect(find.text('Chat Application'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register Now'), findsOneWidget);
    expect(find.text('Forgot your Password?'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Email'), findsNothing);

    await tester.tap(find.text('Register Now'));
    await tester.pumpAndSettle();
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('a saved token opens the home page', (tester) async {
    final store = MemorySessionStore()..token = 'saved-token';
    await tester.pumpWidget(
      BChatApp(
        sessionStore: store,
        authApi: _RestoringApi(),
        chatConnection: _QuietChat(),
      ),
    );
    await tester.pump();

    expect(find.text('Hello, ada'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
  });

  testWidgets('login asks for username and password only', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: LoginScreen(
          onBack: () {},
          onRegister: () {},
          onSubmit: (_, _) async => null,
        ),
      ),
    );

    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Email'), findsNothing);
    expect(find.text('Forgot your Password?'), findsNothing);
  });

  testWidgets('register rejects a malformed email before calling the server', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: RegisterScreen(
          onBack: () {},
          onLogin: () {},
          onSubmit: (_, _, _) async {
            calls += 1;
            return null;
          },
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'ada');
    await tester.enterText(fields.at(1), 'not-an-email');
    await tester.enterText(fields.at(2), 'password1');
    await tester.tap(find.widgetWithText(FilledButton, 'Register Now'));
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(calls, 0);
  });
}
