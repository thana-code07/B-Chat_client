class DemoAccount {
  const DemoAccount({required this.username, required this.password});

  final String username;
  final String password;
}

/// Keep in sync with server/src/demoAccounts.js.
const demoAccounts = [
  DemoAccount(username: 'alex', password: 'demo-alex'),
  DemoAccount(username: 'sam', password: 'demo-sam'),
];
