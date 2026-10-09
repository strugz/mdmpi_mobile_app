/// The vocabulary of the Reconciliation Tracker
/// (docs/application/COLLECTION_RECONCILIATION_TRACKER_PLAN.md).
///
/// Each value carries its wire [code] (the same string the server stores),
/// so the database, the upload and the UI never spell a status differently.
library;

/// Who took a step. The Account's steps are logged by the collector on the
/// client's behalf; the Tracker is the app itself.
enum ReconActor {
  collector('COLLECTOR', 'Collector'),
  account('ACCOUNT', 'Account'),
  tracker('TRACKER', 'Tracker');

  const ReconActor(this.code, this.label);

  final String code;
  final String label;
}

/// Where a case stands. The first three are open; the last three end it.
enum ReconCaseStatus {
  waitingForCollector('WAITING_FOR_COLLECTOR', 'Waiting for collector'),
  waitingForAccount('WAITING_FOR_ACCOUNT', 'Waiting for account'),
  underValidation('UNDER_VALIDATION', 'Under validation'),
  completed('COMPLETED', 'Completed'),
  notCompleted('NOT_COMPLETED', 'Not completed'),
  escalated('ESCALATED', 'Escalated');

  const ReconCaseStatus(this.code, this.label);

  final String code;
  final String label;

  bool get isClosed =>
      this == completed || this == notCompleted || this == escalated;

  static ReconCaseStatus? fromCode(String? code) {
    for (final s in values) {
      if (s.code == code) return s;
    }
    return null;
  }
}

/// Where one invoice of a case stands.
enum ReconInvoiceStatus {
  open('OPEN', 'Open'),
  claimedPaid('CLAIMED_PAID', 'Claimed paid'),
  proofInvalid('PROOF_INVALID', 'Proof invalid'),
  validatedPaid('VALIDATED_PAID', 'Validated paid'),

  /// Paid outside the case (the server reports a zero balance).
  cleared('CLEARED', 'Cleared');

  const ReconInvoiceStatus(this.code, this.label);

  final String code;
  final String label;

  /// Nothing left to reconcile on it.
  bool get isSettled => this == validatedPaid || this == cleared;
}

/// One step of the process. Who does it is fixed by the type, so the
/// collector never picks the actor when logging.
enum ReconActivityType {
  soaSent('SOA_SENT', ReconActor.collector, 'SOA sent'),

  /// The collector chased the account after the SOA. Repeatable.
  followUp('FOLLOW_UP', ReconActor.collector, 'Follow up'),

  /// A collection letter went out, with a photo of it. Repeatable (a first
  /// letter, then a final demand).
  collectionLetterSent(
      'COLLECTION_LETTER_SENT', ReconActor.collector, 'Collection letter sent'),
  documentRequested(
      'DOCUMENT_REQUESTED', ReconActor.account, 'Documents requested'),
  documentProvided(
      'DOCUMENT_PROVIDED', ReconActor.collector, 'Documents provided'),
  paidClaim('PAID_CLAIM', ReconActor.account, 'Claims already paid'),
  proofRequested('PROOF_REQUESTED', ReconActor.collector, 'Proof requested'),
  proofProvided('PROOF_PROVIDED', ReconActor.account, 'Proof sent'),
  proofValidated('PROOF_VALIDATED', ReconActor.collector, 'Proof validated'),

  /// A remark on the timeline. It does not change whose turn it is.
  note('NOTE', ReconActor.collector, 'Note'),
  caseNotCompleted(
      'CASE_NOT_COMPLETED', ReconActor.collector, 'Ended: not completed'),
  caseEscalated('CASE_ESCALATED', ReconActor.collector, 'Escalated'),

  // Logged by the app itself, never picked on the log sheet. They record
  // what happened around the case without changing whose turn it is.

  /// A collection saved on one of the case's invoices (its balance falls by
  /// [ReconActivity.amount]; the balance itself comes from the invoice).
  paymentRecorded('PAYMENT_RECORDED', ReconActor.tracker, 'Payment collected'),

  /// The holder released the account (Done Engagement or Defer): the case
  /// has no holder until someone acquires the account.
  caseReleased('CASE_RELEASED', ReconActor.tracker, 'Released'),

  /// A collector acquired the account; they hold the case now.
  caseAcquired('CASE_ACQUIRED', ReconActor.tracker, 'Acquired');

  const ReconActivityType(this.code, this.doneBy, this.label);

  final String code;
  final ReconActor doneBy;
  final String label;

  /// A step in the back-and-forth: it decides whose turn is next.
  bool get isConversation => !isLifecycle && !isAutomatic && this != note;

  /// Logged by the app, not by the collector.
  bool get isAutomatic =>
      this == paymentRecorded || this == caseReleased || this == caseAcquired;

  /// Ends the case.
  bool get isLifecycle => this == caseNotCompleted || this == caseEscalated;

  /// The stage this step completes, if it is one of the case's stage steps.
  ReconStage? get stage {
    for (final s in ReconStage.values) {
      if (s.type == this) return s;
    }
    return null;
  }

  static ReconActivityType? fromCode(String? code) {
    for (final t in values) {
      if (t.code == code) return t;
    }
    return null;
  }
}

/// The case-level escalation path, in order: SOA, then Follow up, then the
/// Collection Letter. It runs beside the invoices' claim → proof → validate
/// chain and never decides the case's status. A stage is done once its step
/// has been logged in order; each step may be logged again.
enum ReconStage {
  soa('SOA', ReconActivityType.soaSent),
  followUp('Follow up', ReconActivityType.followUp),
  collectionLetter('Collection letter', ReconActivityType.collectionLetterSent);

  const ReconStage(this.label, this.type);

  final String label;

  /// The step that completes it.
  final ReconActivityType type;

  /// The stage that must be done first; null for the first.
  ReconStage? get previous => index == 0 ? null : values[index - 1];

  /// The label mid-sentence ("before any follow up"); SOA stays capitalised.
  String get inSentence => this == soa ? label : label.toLowerCase();

  /// Why this stage's step cannot be logged until [previous] is done; null
  /// for the first stage.
  String? get lockReason => switch (previous) {
        null => null,
        ReconStage.soa => 'Log the SOA before a follow up.',
        final p => 'Log at least one ${p.inSentence} before the '
            '$inSentence.',
      };
}

/// The collector's verdict on a proof of payment.
enum ReconValidationResult {
  valid('VALID'),
  invalid('INVALID');

  const ReconValidationResult(this.code);

  final String code;

  static ReconValidationResult? fromCode(String? code) {
    for (final r in values) {
      if (r.code == code) return r;
    }
    return null;
  }
}

/// Alerts on an open case.
enum ReconFlag {
  noResponse('NO_RESPONSE', 'No response'),
  claimedPaidNoProof('CLAIMED_PAID_NO_PROOF', 'Claimed paid, no proof yet'),
  nextActionOverdue('NEXT_ACTION_OVERDUE', 'Next action overdue');

  const ReconFlag(this.code, this.label);

  final String code;
  final String label;
}
