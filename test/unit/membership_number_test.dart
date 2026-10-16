import 'package:family_accounting_app/app/utils/membership_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MembershipNumberParser', () {
    test('extracts trailing number from last name', () {
      final result = MembershipNumberParser.extractFromNames(
        firstName: 'علی',
        lastName: 'رضایی ۱۲۳',
      );
      expect(result.firstName, 'علی');
      expect(result.lastName, 'رضایی');
      expect(result.membershipNumber, '۱۲۳');
    });

    test('extracts leading number from first name', () {
      final result = MembershipNumberParser.extractFromNames(
        firstName: '45 محمد',
        lastName: 'احمدی',
      );
      expect(result.firstName, 'محمد');
      expect(result.lastName, 'احمدی');
      expect(result.membershipNumber, '45');
    });

    test('keeps existing membership and names', () {
      final result = MembershipNumberParser.extractFromNames(
        firstName: 'علی 9',
        lastName: 'رضایی',
        existingMembership: '100',
      );
      expect(result.firstName, 'علی 9');
      expect(result.lastName, 'رضایی');
      expect(result.membershipNumber, '100');
    });
  });
}
