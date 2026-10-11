final usernamePattern = RegExp(r'^[a-zA-Z0-9_]{3,32}$');
final emailPattern = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

const usernameRule =
    'Username must be 3-32 characters and use only letters, numbers, and underscores';
const emailRule = 'Enter a valid email address';
const passwordRule = 'Password must be 8-72 characters';

String? validateUsername(String value) {
  if (!usernamePattern.hasMatch(value.trim())) return usernameRule;
  return null;
}

String? validateEmail(String value) {
  final email = value.trim();
  if (email.isEmpty || email.length > 254 || !emailPattern.hasMatch(email)) {
    return emailRule;
  }
  return null;
}

String? validatePassword(String value) {
  if (value.length < 8 || value.length > 72) return passwordRule;
  return null;
}
