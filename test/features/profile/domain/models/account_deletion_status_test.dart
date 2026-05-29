import 'package:flutter_test/flutter_test.dart';
import 'package:tander_flutter_v3/features/profile/domain/models/account_deletion_status.dart';

void main() {
  group('AccountDeletionStatus.fromJson', () {
    test('parses a full GRACE-window response', () {
      final status = AccountDeletionStatus.fromJson(const {
        'id': 'del_123',
        'status': 'GRACE',
        'requestedAt': '2026-05-28T10:00:00Z',
        'graceUntil': '2026-06-27T10:00:00Z',
      });

      // No `==` override on the model — assert field-by-field.
      expect(status.id, 'del_123');
      expect(status.status, 'GRACE');
      expect(status.requestedAt, DateTime.utc(2026, 5, 28, 10));
      expect(status.graceUntil, DateTime.utc(2026, 6, 27, 10));
      expect(status.executedAt, isNull);
      expect(status.cancelledAt, isNull);
      expect(status.isPending, isTrue);
    });

    test('coerces missing id/status to empty strings', () {
      final status = AccountDeletionStatus.fromJson(const {});

      expect(status.id, '');
      expect(status.status, '');
      expect(status.requestedAt, isNull);
      expect(status.isPending, isFalse);
    });

    test('stringifies non-string id and status', () {
      final status = AccountDeletionStatus.fromJson(const {
        'id': 42,
        'status': 99,
      });

      expect(status.id, '42');
      expect(status.status, '99');
    });

    test('ignores empty and malformed date strings', () {
      final status = AccountDeletionStatus.fromJson(const {
        'id': 'x',
        'status': 'EXECUTED',
        'requestedAt': '',
        'graceUntil': 'not-a-date',
        'executedAt': '2026-05-28T12:30:00Z',
      });

      expect(status.requestedAt, isNull);
      expect(status.graceUntil, isNull);
      expect(status.executedAt, DateTime.utc(2026, 5, 28, 12, 30));
    });
  });

  group('AccountDeletionStatus.isPending', () {
    test('is true only for GRACE (case-insensitive)', () {
      expect(_withStatus('GRACE').isPending, isTrue);
      expect(_withStatus('grace').isPending, isTrue);
      expect(_withStatus('Grace').isPending, isTrue);
    });

    test('is false for terminal and unknown states', () {
      expect(_withStatus('EXECUTED').isPending, isFalse);
      expect(_withStatus('CANCELLED').isPending, isFalse);
      expect(_withStatus('').isPending, isFalse);
    });
  });
}

AccountDeletionStatus _withStatus(String status) =>
    AccountDeletionStatus(id: 'id', status: status, requestedAt: null);
