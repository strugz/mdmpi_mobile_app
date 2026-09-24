/// How the server answered one `PATCH /api4/request`.
enum DeliveryUpdateStatus {
  /// The server confirmed the update.
  updated,

  /// The server refused it (409): the request is done, the status would move
  /// backwards, or this copy is older than what the server holds. Nothing was
  /// changed, and re-sending the same copy will be refused again.
  rejected,

  /// The update did not go through for any other reason (network, 404,
  /// unconfirmed 200). Worth retrying.
  failed,
}

class DeliveryUpdateOutcome {
  const DeliveryUpdateOutcome._(this.status, this.message,
      {this.sameStatus = false});

  /// [sameStatus]: the server already held the status that was sent. The
  /// update was still applied, but nothing moved forward.
  const DeliveryUpdateOutcome.updated(
      [String message = '', bool sameStatus = false])
      : this._(DeliveryUpdateStatus.updated, message, sameStatus: sameStatus);

  const DeliveryUpdateOutcome.rejected(String reason)
      : this._(DeliveryUpdateStatus.rejected, reason);

  const DeliveryUpdateOutcome.failed(String reason)
      : this._(DeliveryUpdateStatus.failed, reason);

  final DeliveryUpdateStatus status;

  /// Only meaningful for [DeliveryUpdateStatus.updated]; see [updated].
  final bool sameStatus;

  /// The server's confirmation, or why the update was not applied.
  final String message;

  bool get isUpdated => status == DeliveryUpdateStatus.updated;
}
