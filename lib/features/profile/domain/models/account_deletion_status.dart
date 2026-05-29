/// Snapshot of the user's account-deletion request.
///
/// Mirrors the backend `DeletionResponse`
/// (`/privacy/account-deletion`, POST/GET/cancel). Account deletion is a
/// *scheduled* operation with a 30-day grace window: the account stays usable
/// until [graceUntil], and the request can be cancelled until then.
class AccountDeletionStatus {
  const AccountDeletionStatus({
    required this.id,
    required this.status,
    required this.requestedAt,
    this.graceUntil,
    this.executedAt,
    this.cancelledAt,
  });

  final String id;

  /// Backend status, e.g. `GRACE`, `EXECUTED`, `CANCELLED`.
  final String status;

  final DateTime? requestedAt;

  /// When the deletion executes if not cancelled (end of the grace window).
  final DateTime? graceUntil;

  final DateTime? executedAt;
  final DateTime? cancelledAt;

  /// True while the request is in its grace window and can still be cancelled.
  bool get isPending => status.toUpperCase() == 'GRACE';

  factory AccountDeletionStatus.fromJson(Map<String, Object?> json) {
    DateTime? parseDate(Object? value) =>
        value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;

    return AccountDeletionStatus(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      requestedAt: parseDate(json['requestedAt']),
      graceUntil: parseDate(json['graceUntil']),
      executedAt: parseDate(json['executedAt']),
      cancelledAt: parseDate(json['cancelledAt']),
    );
  }
}
