import 'package:client/data/chat_api.dart';
import 'package:client/validation/credentials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('password limit follows bytes so bcrypt cannot truncate it', () {
    expect(validatePassword('password1'), isNull);
    expect(validatePassword('é' * 40), passwordRule);
  });

  test('status receipts do not move backwards', () {
    expect(statusMovesForward('sent', 'read'), isTrue);
    expect(statusMovesForward('read', 'delivered'), isFalse);
    expect(statusMovesForward('delivered', 'delivered'), isTrue);
  });
}
