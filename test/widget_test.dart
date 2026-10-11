import 'package:client/app.dart';
import 'package:client/data/auth_api.dart';
import 'package:client/data/chat_api.dart';
import 'package:client/data/chat_connection.dart';
import 'package:client/data/session_store.dart';
import 'package:client/screens/inbox_screen.dart';
import 'package:client/screens/login_screen.dart';
import 'package:client/screens/register_screen.dart';
import 'package:client/screens/thread_screen.dart';
import 'package:client/theme/app_colors.dart';
import 'package:client/widgets/chat_bubble.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _RestoringApi extends AuthApi {
  _RestoringApi() : super(dio: Dio(BaseOptions(baseUrl: 'http://localhost')));

  @override
  Future<SessionUser> me(String token) async {
    return const SessionUser(id: 'user-1', username: 'ada');
  }

  @override
  Future<void> logout(String token) async {}
}

class _EmptyThreadApi extends ChatApi {
  _EmptyThreadApi() : super(dio: Dio(BaseOptions(baseUrl: 'http://localhost')));

  @override
  Future<MessagePage> messages(String token, String userId, {int page = 1}) async {
    return const MessagePage(messages: [], page: 1, totalPages: 0);
  }
}

class _EmptyChatApi extends ChatApi {
  _EmptyChatApi() : super(dio: Dio(BaseOptions(baseUrl: 'http://localhost')));

  @override
  Future<List<Conversation>> conversations(String token) async => [];

  @override
  Future<List<ChatUser>> searchUsers(String token, String query) async {
    if (query == 'ada') return const [ChatUser(id: 'user-2', username: 'ada')];
    return const [];
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

  testWidgets('a saved token opens direct messages', (tester) async {
    final store = MemorySessionStore()..token = 'saved-token';
    await tester.pumpWidget(
      BChatApp(
        sessionStore: store,
        authApi: _RestoringApi(),
        chatConnection: _QuietChat(),
        chatApi: _EmptyChatApi(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Direct Messages'), findsOneWidget);
    expect(find.byTooltip('New chat'), findsOneWidget);
    expect(find.byTooltip('Logout'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
    expect(find.text('No conversations yet'), findsOneWidget);

    await tester.tap(find.byTooltip('New chat'));
    await tester.pump();
    expect(find.text('New Chat'), findsOneWidget);
    expect(find.text('Search users...'), findsOneWidget);
    expect(find.text('ada'), findsNothing);

    await tester.enterText(find.byType(TextField), 'ada');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(find.widgetWithText(ListTile, 'ada'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    expect(find.text('Direct Messages'), findsOneWidget);

    await tester.tap(find.byTooltip('Logout'));
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
    expect(store.token, isNull);
  });

  testWidgets('online bar keeps offline conversations in the chat list only', (tester) async {
    final ada = Conversation(
      chatroomId: 'room-ada',
      user: const ChatUser(id: 'ada', username: 'ada'),
      isOnline: true,
      lastMessage: LastMessage(
        message: 'hello',
        createdAt: DateTime.utc(2026, 7, 15, 3, 8),
        status: 'read',
        sender: 'ada',
      ),
    );
    final bob = Conversation(
      chatroomId: 'room-bob',
      user: const ChatUser(id: 'bob', username: 'bob'),
      isOnline: false,
      lastMessage: LastMessage(
        message: 'later',
        createdAt: DateTime.utc(2026, 7, 13, 23, 36),
        status: 'sent',
        sender: 'bob',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: InboxScreen(
          conversations: [ada, bob],
          loading: false,
          error: null,
          loggingOut: false,
          onLogout: () {},
          onNewChat: () {},
          onOpen: (_) {},
          onRetry: () {},
        ),
      ),
    );

    expect(find.bySemanticsLabel('ada, online'), findsOneWidget);
    expect(find.bySemanticsLabel('bob, online'), findsNothing);
    expect(find.text('bob'), findsOneWidget);
    expect(find.text('Chat Room'), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('message checks follow sent, delivered, and read', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ChatBubble(message: 'one', time: 'Jul 15, 3:08 AM', mine: true, status: 'sent'),
              ChatBubble(message: 'two', time: 'Jul 15, 3:09 AM', mine: true, status: 'delivered'),
              ChatBubble(message: 'three', time: 'Jul 15, 3:10 AM', mine: true, status: 'read'),
              ChatBubble(message: 'theirs', time: 'Jul 15, 3:11 AM', mine: false, status: 'read'),
            ],
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Delivered'), findsOneWidget);
    expect(find.bySemanticsLabel('Read'), findsOneWidget);
    expect(find.byIcon(Icons.done_all), findsNWidgets(2));
    final icons = tester.widgetList<Icon>(find.byIcon(Icons.done_all)).toList();
    expect(icons[0].color, AppColors.deliveredReceipt);
    expect(icons[1].color, AppColors.readReceipt);
  });

  testWidgets('an empty chat shows the prompt and online status', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ThreadScreen(
          token: 'token',
          selfId: 'user-1',
          peer: const OpenChat(
            chatroomId: 'room',
            user: ChatUser(id: 'user-2', username: 'rajat'),
            isOnline: true,
          ),
          api: _EmptyThreadApi(),
          chat: _QuietChat(),
          onBack: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('rajat'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('No messages yet.'), findsOneWidget);
    expect(find.text('Send a message to start the conversation!'), findsOneWidget);
    expect(find.text('Type a message'), findsOneWidget);
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
