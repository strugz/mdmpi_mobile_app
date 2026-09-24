import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_advance_dao.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/collection_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';

/// An Advanced Payment is float. Applied to an invoice it covers what the
/// invoice is due, and whatever it does not need stays float, on the same
/// advance, for the next invoice — the server spreads one payment the same
/// way. It used to leave the list entirely, losing the excess on the phone.

class _Repo extends CollectionRepository {
  final calls = <({CollectionAdvanceRecord advance, double applied})>[];

  @override
  Future<bool> assignAdvance({
    required CollectionAdvanceRecord advance,
    required CollectionItemModel newInvoice,
    required double amountDue,
    required String dueDate,
    required String appliedAt,
    required double appliedAmount,
  }) async {
    calls.add((advance: advance, applied: appliedAmount));
    return true;
  }
}

class _Activity extends CollectionActivityController {
  _Activity(this._repo);
  final _Repo _repo;

  // The real onInit wires the database-backed repositories and starts
  // loading; the fake repository is all this test needs.
  @override
  // ignore: must_call_super
  void onInit() => repository = _repo;
}

({_Activity activity, _Repo repo}) _seed(double advance) {
  final repo = _Repo();
  final activity =
      Get.put<CollectionActivityController>(_Activity(repo)) as _Activity;
  activity.unassignedAdvancedPayments.assignAll([
    {
      'id': 'AP-1',
      'clientId': 'C1',
      'clientName': 'Antipolo Doctors Hospital',
      'amount': advance,
      'remarks': '',
      'date': '2026-09-24T07:19:53.266764',
      'collectorName': 'Jay',
    },
  ]);
  return (activity: activity, repo: repo);
}

Future<double> _apply(_Activity a, String invoice, double due) =>
    a.assignInvoiceToPayment(
      paymentId: 'AP-1',
      invoiceNumber: invoice,
      amountDue: due,
      dueDate: '2026-10-30',
      collectionDate: DateTime(2026, 9, 24),
    );

void main() {
  tearDown(Get.reset);

  test('an advance larger than the invoice keeps the excess as float',
      () async {
    final s = _seed(750000);

    final left = await _apply(s.activity, 'SI-1', 500000);

    expect(left, 250000);
    expect(s.repo.calls.single.applied, 500000,
        reason: 'only what the invoice was due counts as collected');
    final waiting = s.activity.unassignedAdvancedPayments.single;
    expect(waiting['id'], 'AP-1', reason: 'the same advance, not a new one');
    expect(waiting['amount'], 250000);
    final invoice = s.activity.bucketItems.single;
    expect(invoice.toBeCollected, 0, reason: 'the invoice is settled');
  });

  test('an advance smaller than the invoice is spent and leaves the list',
      () async {
    final s = _seed(500000);

    final left = await _apply(s.activity, 'SI-1', 750000);

    expect(left, 0);
    expect(s.repo.calls.single.applied, 500000);
    expect(s.activity.unassignedAdvancedPayments, isEmpty);
    expect(s.activity.bucketItems.single.toBeCollected, 250000,
        reason: 'the invoice waits for the rest');
  });

  test('the float left over goes onto the next invoice', () async {
    final s = _seed(750000);

    await _apply(s.activity, 'SI-1', 500000);
    final left = await _apply(s.activity, 'SI-2', 250000);

    expect(left, 0);
    expect(s.repo.calls.map((c) => c.applied), [500000, 250000]);
    expect(s.repo.calls.last.advance.externalRef, 'AP-1');
    expect(s.repo.calls.last.advance.amount, 250000,
        reason: 'the second invoice draws on the remainder only');
    expect(s.activity.unassignedAdvancedPayments, isEmpty);
  });
}
