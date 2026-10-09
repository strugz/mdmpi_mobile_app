import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_clock.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_evaluation.dart';

/// Settings the team may tune.
class ReconSettings {
  const ReconSettings({this.noResponseDays = 7});

  /// Days waiting on the Account before a case is flagged No response.
  final int noResponseDays;
}

/// A balance at or below this is paid (floating-point pennies).
const double _paidEpsilon = 0.005;

/// Where [reconCase] stands at [now], worked out from its activity log alone.
///
/// The one place the Tracker's rules live
/// (docs/application/COLLECTION_RECONCILIATION_TRACKER_PLAN.md, "Rules").
/// Pure: the same case, invoices, activities and [now] always give the same
/// answer, on any device, so two phones that logged steps offline agree as
/// soon as they have each other's activities.
///
/// [activities] may be in any order; they are applied oldest first, ties
/// broken by id so every device orders them alike. [now] is a real instant
/// (`DateTime.now()`); days are counted in Philippine calendar days.
ReconEvaluation evaluateReconCase({
  required ReconCase reconCase,
  required List<ReconCaseInvoice> invoices,
  required List<ReconActivity> activities,
  required DateTime now,
  ReconSettings settings = const ReconSettings(),
}) {
  final warnings = <String>[];
  final today = BReconClock.fromInstant(now);
  final opened = BReconClock.parse(reconCase.dateOpened) ?? today;

  final states = <String, _InvoiceState>{
    for (final inv in invoices) inv.invoiceNo.trim(): _InvoiceState(inv),
  };

  // Oldest first; an unreadable time cannot be placed, so it is reported.
  final timed = <({DateTime at, ReconActivity a})>[];
  for (final a in activities) {
    final at = BReconClock.parse(a.dateTime);
    if (at == null) {
      warnings.add('${a.activityId}: unreadable time "${a.dateTime}", skipped');
      continue;
    }
    timed.add((at: at, a: a));
  }
  timed.sort((x, y) {
    final byTime = x.at.compareTo(y.at);
    return byTime != 0 ? byTime : x.a.activityId.compareTo(y.a.activityId);
  });

  ReconCaseStatus? endedAs;
  DateTime? endedAt;
  ReconActivity? lastActivity;
  DateTime? lastActivityAt;
  ReconActivity? lastLogged;
  ReconActivity? lastConversation;
  // The first collector step since the Account last acted: the start of the
  // wait that No response measures.
  DateTime? waitingOnAccountSince;
  DateTime? soaDate;
  double? soaAmount;
  // Stage steps counted in order, per stage: (count, first, latest).
  final stageCount = List<int>.filled(ReconStage.values.length, 0);
  final stageFirst = List<DateTime?>.filled(ReconStage.values.length, null);
  final stageLast = List<DateTime?>.filled(ReconStage.values.length, null);

  /// Counts a stage step, unless the stage before it is not done yet.
  void stageStep(ReconActivity a, ReconStage stage, DateTime at) {
    final previous = stage.previous;
    if (previous != null && stageCount[previous.index] == 0) {
      warnings.add('${a.activityId}: ${stage.inSentence} before any '
          '${previous.inSentence}, not counted');
      return;
    }
    stageCount[stage.index]++;
    stageFirst[stage.index] ??= at;
    stageLast[stage.index] = at;
  }

  /// The named invoices this step can touch; unknown numbers are reported.
  List<_InvoiceState> named(ReconActivity a) {
    final found = <_InvoiceState>[];
    for (final raw in a.invoiceNos) {
      final no = raw.trim();
      if (no.isEmpty) continue;
      final s = states[no];
      if (s == null) {
        warnings.add('${a.activityId}: invoice $no is not in this case');
      } else if (!found.contains(s)) {
        found.add(s);
      }
    }
    return found;
  }

  void noTargets(ReconActivity a, List<_InvoiceState> targets, String what) {
    if (targets.isEmpty) warnings.add('${a.activityId}: no invoice $what');
  }

  for (final (:at, :a) in timed) {
    if (endedAs != null) {
      warnings.add('${a.activityId}: ${a.type.label} after the case ended, '
          'not applied');
      continue;
    }
    lastActivity = a;
    lastActivityAt = at;
    if (!a.type.isAutomatic) lastLogged = a;

    switch (a.type) {
      case ReconActivityType.soaSent:
        named(a); // checked for unknown numbers; the SOA covers all open ones
        soaDate = at;
        soaAmount = a.amount ??
            states.values
                .where((s) => !s.status.isSettled)
                .fold<double>(0, (sum, s) => sum + s.owed);
        stageStep(a, ReconStage.soa, at);

      // Case-level: they name no invoices.
      case ReconActivityType.followUp:
      case ReconActivityType.collectionLetterSent:
        stageStep(a, a.type.stage!, at);

      case ReconActivityType.documentRequested:
      case ReconActivityType.documentProvided:
      case ReconActivityType.note:
      case ReconActivityType.paymentRecorded:
      case ReconActivityType.caseReleased:
      case ReconActivityType.caseAcquired:
        named(a);

      case ReconActivityType.paidClaim:
        final targets = named(a);
        if (a.invoiceNos.every((n) => n.trim().isEmpty)) {
          warnings.add('${a.activityId}: a paid claim names no invoice');
        }
        for (final s in targets) {
          if (s.status.isSettled) {
            warnings.add('${a.activityId}: invoice ${s.no} is already '
                '${s.status.label.toLowerCase()}');
          } else if (s.status != ReconInvoiceStatus.claimedPaid) {
            s.claim();
          }
        }

      case ReconActivityType.proofRequested:
        final targets = a.invoiceNos.isEmpty
            ? states.values.where((s) => s.awaitsProof).toList()
            : named(a);
        noTargets(a, targets, 'is claimed paid and waiting for proof');
        for (final s in targets) {
          if (s.status == ReconInvoiceStatus.claimedPaid && !s.proofPending) {
            s.proofRequested = true;
          } else {
            warnings.add('${a.activityId}: invoice ${s.no} is not claimed '
                'paid and waiting for proof');
          }
        }

      case ReconActivityType.proofProvided:
        final targets = a.invoiceNos.isEmpty
            ? states.values.where((s) => s.awaitsProof).toList()
            : named(a);
        noTargets(a, targets, 'is waiting for proof');
        for (final s in targets) {
          if (s.status.isSettled) {
            warnings.add('${a.activityId}: invoice ${s.no} is already '
                '${s.status.label.toLowerCase()}');
            continue;
          }
          // Proof for an invoice nobody claimed yet is the claim itself.
          if (s.status != ReconInvoiceStatus.claimedPaid) s.claim();
          s.proofPending = true;
          s.proofRequested = false;
        }

      case ReconActivityType.proofValidated:
        final result = a.validationResult;
        if (result == null) {
          warnings.add('${a.activityId}: a validation without a result');
          break;
        }
        final targets = a.invoiceNos.isEmpty
            ? states.values.where((s) => s.proofPending).toList()
            : named(a);
        noTargets(a, targets, 'has proof waiting to be validated');
        for (final s in targets) {
          if (!s.proofPending) {
            warnings.add('${a.activityId}: invoice ${s.no} has no proof '
                'waiting to be validated');
            continue;
          }
          s.proofPending = false;
          if (result == ReconValidationResult.valid) {
            s.status = ReconInvoiceStatus.validatedPaid;
            s.settledAt = at;
          } else {
            s.status = ReconInvoiceStatus.proofInvalid;
          }
        }

      case ReconActivityType.caseNotCompleted:
        endedAs = ReconCaseStatus.notCompleted;
        endedAt = at;

      case ReconActivityType.caseEscalated:
        endedAs = ReconCaseStatus.escalated;
        endedAt = at;
    }

    if (a.type.isConversation) {
      if (a.doneBy == ReconActor.collector) {
        if (lastConversation?.doneBy != ReconActor.collector) {
          waitingOnAccountSince = at;
        }
      } else {
        waitingOnAccountSince = null;
      }
      lastConversation = a;
    }
  }

  // Paid outside the case: the server's balance reached zero without a
  // validation here.
  for (final s in states.values) {
    final balance = s.invoice.currentBalance;
    if (balance != null &&
        balance <= _paidEpsilon &&
        s.status != ReconInvoiceStatus.validatedPaid) {
      s.status = ReconInvoiceStatus.cleared;
      s.proofPending = false;
      s.proofRequested = false;
      s.settledAt = BReconClock.parse(s.invoice.clearedAt) ?? lastActivityAt;
    }
  }

  final ReconCaseStatus status;
  DateTime? dateClosed;
  if (endedAs != null) {
    status = endedAs;
    dateClosed = endedAt;
  } else if (states.isNotEmpty &&
      states.values.every((s) => s.status.isSettled)) {
    status = ReconCaseStatus.completed;
    dateClosed = states.values
        .map((s) => s.settledAt)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (m, t) => m == null || t.isAfter(m) ? t : m);
  } else if (states.values.any((s) => s.proofPending)) {
    status = ReconCaseStatus.underValidation;
  } else if (lastConversation?.doneBy == ReconActor.collector) {
    status = ReconCaseStatus.waitingForAccount;
  } else {
    status = ReconCaseStatus.waitingForCollector;
  }

  final ReconActor? nextActor = switch (status) {
    ReconCaseStatus.waitingForAccount => ReconActor.account,
    ReconCaseStatus.waitingForCollector ||
    ReconCaseStatus.underValidation =>
      ReconActor.collector,
    _ => null,
  };

  final flags = <ReconFlag>{};
  if (!status.isClosed) {
    if (status == ReconCaseStatus.waitingForAccount &&
        waitingOnAccountSince != null &&
        BReconClock.daysBetween(waitingOnAccountSince, today) >=
            settings.noResponseDays) {
      flags.add(ReconFlag.noResponse);
    }
    if (states.values.any((s) => s.proofRequested)) {
      flags.add(ReconFlag.claimedPaidNoProof);
    }
    // The collector's own latest step sets the next action; a payment or a
    // release the app logged since does not clear it.
    final due = BReconClock.parse(lastLogged?.nextActionDueDate);
    if (due != null && BReconClock.daysBetween(due, today) > 0) {
      flags.add(ReconFlag.nextActionOverdue);
    }
  }

  final end = dateClosed ?? today;
  return ReconEvaluation(
    status: status,
    nextActor: nextActor,
    invoices: [
      for (final s in states.values)
        ReconInvoiceState(
          invoiceNo: s.no,
          amount: s.owed,
          status: s.status,
          proofPending: s.proofPending,
          proofRequested: s.proofRequested,
        ),
    ],
    flags: flags,
    warnings: warnings,
    lastActivity: lastActivity,
    daysSinceLastActivity:
        BReconClock.daysBetween(lastActivityAt ?? opened, today),
    daysOpen: BReconClock.daysBetween(opened, end),
    dateClosed: dateClosed,
    soaDate: soaDate,
    soaAmount: soaAmount,
    stages: [
      for (final stage in ReconStage.values)
        ReconStageProgress(
          stage: stage,
          count: stageCount[stage.index],
          firstAt: stageFirst[stage.index],
          lastAt: stageLast[stage.index],
        ),
    ],
  );
}

/// The mutable working copy of one invoice while the log is replayed.
class _InvoiceState {
  _InvoiceState(this.invoice);

  final ReconCaseInvoice invoice;
  ReconInvoiceStatus status = ReconInvoiceStatus.open;
  bool proofPending = false;
  bool proofRequested = false;
  DateTime? settledAt;

  String get no => invoice.invoiceNo.trim();

  double get owed => invoice.currentBalance ?? invoice.amount;

  /// Claimed paid, and no proof in hand yet.
  bool get awaitsProof =>
      status == ReconInvoiceStatus.claimedPaid && !proofPending;

  /// A new claim starts over: any earlier request was for an earlier claim.
  void claim() {
    status = ReconInvoiceStatus.claimedPaid;
    proofPending = false;
    proofRequested = false;
  }
}
