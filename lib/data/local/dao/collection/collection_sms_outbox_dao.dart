import 'dart:convert';

import 'package:sqflite/sqflite.dart';

/// Where one Collection SMS stands.
abstract final class SmsOutboxStatus {
  /// Saved, not yet sent (or the app closed while it was going out).
  static const pending = 'Pending';

  /// The radio reported SENT for every recipient.
  static const sent = 'Sent';

  /// Accepted by the phone, but not every recipient was confirmed.
  static const unconfirmed = 'Unconfirmed';

  /// Nobody received it.
  static const failed = 'Failed';

  /// SMS permission refused: the Messages app was opened with the text.
  static const handedOff = 'HandedOff';

  /// No Head with a number and no Collection contact when it was sent.
  static const noRecipients = 'NoRecipients';

  /// Statuses the collector should look at: something did not go out.
  static const needsAttention = {pending, unconfirmed, failed, noRecipients};
}

/// How the send to one number ended.
abstract final class SmsRecipientResult {
  static const pending = 'Pending';
  static const sent = 'Sent';
  static const unconfirmed = 'Unconfirmed';
  static const failed = 'Failed';
  static const handedOff = 'HandedOff';
}

/// One recipient of a Collection SMS and how its send ended.
class SmsOutboxRecipient {
  const SmsOutboxRecipient(this.number, this.result);

  final String number;

  /// One of [SmsRecipientResult].
  final String result;

  bool get confirmed => result == SmsRecipientResult.sent;

  Map<String, String> toJson() => {'number': number, 'result': result};
}

/// One Collection SMS as it was sent, kept so a message that did not go out
/// can be seen and sent again from Settings → SMS Outbox.
class SmsOutboxRecord {
  const SmsOutboxRecord({
    required this.id,
    required this.createdAt,
    required this.kind,
    required this.message,
    this.headOnly = false,
    this.status = SmsOutboxStatus.pending,
    this.recipients = const [],
    this.attempts = 0,
    this.lastError,
    this.lastAttemptAt,
  });

  final String id;

  /// ISO 8601, local time.
  final String createdAt;

  /// Which trigger sent it ("Saving Engagement", "Adding Deposit", ...).
  final String kind;

  /// The text as sent, the collector's initials included.
  final String message;

  final bool headOnly;

  /// One of [SmsOutboxStatus].
  final String status;

  final List<SmsOutboxRecipient> recipients;
  final int attempts;
  final String? lastError;
  final String? lastAttemptAt;

  bool get needsAttention => SmsOutboxStatus.needsAttention.contains(status);

  /// The numbers a hand Resend goes to: every original recipient not
  /// confirmed, "not confirmed" ones included.
  List<String> get unconfirmedNumbers =>
      [for (final r in recipients) if (!r.confirmed) r.number];

  /// The numbers the background dispatch tries: never sent, or failed. A
  /// "not confirmed" number is left for a hand Resend, since the phone did
  /// accept it and sending again might text it twice.
  List<String> get retryableNumbers => [
        for (final r in recipients)
          if (r.result == SmsRecipientResult.pending ||
              r.result == SmsRecipientResult.failed)
            r.number,
      ];

  /// The first line: what happened and to whom.
  String get headline => message.split('\n').first.trim();

  SmsOutboxRecord copyWith({
    String? status,
    List<SmsOutboxRecipient>? recipients,
    int? attempts,
    String? lastError,
    bool clearError = false,
    String? lastAttemptAt,
  }) =>
      SmsOutboxRecord(
        id: id,
        createdAt: createdAt,
        kind: kind,
        message: message,
        headOnly: headOnly,
        status: status ?? this.status,
        recipients: recipients ?? this.recipients,
        attempts: attempts ?? this.attempts,
        lastError: clearError ? null : (lastError ?? this.lastError),
        lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      );

  Map<String, Object?> toRow() => {
        'id': id,
        'createdAt': createdAt,
        'kind': kind,
        'message': message,
        'headOnly': headOnly ? 1 : 0,
        'status': status,
        'recipients': jsonEncode([for (final r in recipients) r.toJson()]),
        'attempts': attempts,
        'lastError': lastError,
        'lastAttemptAt': lastAttemptAt,
      };

  factory SmsOutboxRecord.fromRow(Map<String, Object?> r) {
    String s(String k) => (r[k] ?? '').toString();
    final recipients = <SmsOutboxRecipient>[];
    try {
      final decoded = jsonDecode(s('recipients').isEmpty ? '[]' : s('recipients'));
      if (decoded is List) {
        for (final e in decoded) {
          if (e is Map) {
            recipients.add(SmsOutboxRecipient(
              (e['number'] ?? '').toString(),
              (e['result'] ?? SmsRecipientResult.pending).toString(),
            ));
          }
        }
      }
    } catch (_) {}
    return SmsOutboxRecord(
      id: s('id'),
      createdAt: s('createdAt'),
      kind: s('kind'),
      message: s('message'),
      headOnly: (r['headOnly'] as num?)?.toInt() == 1,
      status: s('status').isEmpty ? SmsOutboxStatus.pending : s('status'),
      recipients: recipients,
      attempts: (r['attempts'] as num?)?.toInt() ?? 0,
      lastError: r['lastError']?.toString(),
      lastAttemptAt: r['lastAttemptAt']?.toString(),
    );
  }
}

/// The Collection SMS outbox: every message the app sent, and how it went.
class CollectionSmsOutboxDao {
  CollectionSmsOutboxDao(this.db);

  final Database db;

  static const table = 'a_tblCollectionSmsOutbox';

  Future<void> insert(SmsOutboxRecord record) =>
      db.insert(table, record.toRow(),
          conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> update(SmsOutboxRecord record) => db.update(
      table, record.toRow(),
      where: 'id = ?', whereArgs: [record.id]);

  Future<SmsOutboxRecord?> getById(String id) async {
    final rows =
        await db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : SmsOutboxRecord.fromRow(rows.first);
  }

  /// Every message, newest first.
  Future<List<SmsOutboxRecord>> getAll() async => [
        for (final r in await db.query(table, orderBy: 'createdAt DESC, id DESC'))
          SmsOutboxRecord.fromRow(r),
      ];

  Future<int> countNeedingAttention() async {
    final statuses = SmsOutboxStatus.needsAttention.toList();
    final rows = await db.rawQuery(
        'SELECT COUNT(*) AS n FROM $table WHERE status IN '
        '(${List.filled(statuses.length, '?').join(', ')})',
        statuses);
    return (rows.first['n'] as num?)?.toInt() ?? 0;
  }

  Future<void> delete(String id) =>
      db.delete(table, where: 'id = ?', whereArgs: [id]);

  /// Removes messages that went out (sent, or handed to the Messages app by
  /// an older build) before [cutoff] (ISO 8601): the Outbox keeps the day's.
  /// Ones that did not go out stay until they go out or are discarded.
  /// Returns how many were removed.
  Future<int> purgeDeliveredBefore(String cutoff) => db.delete(
        table,
        where: 'status IN (?, ?) AND createdAt < ?',
        whereArgs: [SmsOutboxStatus.sent, SmsOutboxStatus.handedOff, cutoff],
      );
}
