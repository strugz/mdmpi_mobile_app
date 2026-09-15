import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';

/// After Upload All the controller reloads every local item; claimed invoices
/// must land in Activity (not also in Bucket) and history must be counted once.
void main() {
  CollectionItemModel item(String id, {String assignedAt = 'N/A', double balance = 100, List<CollectionHistoryModel> history = const []}) =>
      CollectionItemModel.fromJson({
        'id': id,
        'Client': {'ACCMID': 'C1', 'ACCMSC': 'NLN-1', 'ACCMNM': 'Client'},
        'ToBeCollected': balance,
        'TotalCollected': 0,
        'AssignedAt': assignedAt,
        'History': history.map((h) => h.toJson()).toList(),
      });

  group('isClaimedOpen', () {
    test('server null (N/A) and locally released (empty) are Bucket', () {
      expect(CollectionActivityController.isClaimedOpen(item('a', assignedAt: 'N/A')), isFalse);
      expect(CollectionActivityController.isClaimedOpen(item('b', assignedAt: '')), isFalse);
      expect(CollectionActivityController.isClaimedOpen(item('c', assignedAt: '   ')), isFalse);
    });

    test('claimed with an open balance is Activity', () {
      expect(CollectionActivityController.isClaimedOpen(item('a', assignedAt: '2026-09-15T08:00:00')), isTrue);
      expect(CollectionActivityController.isClaimedOpen(item('b', assignedAt: '2026-09-15 08:00')), isTrue);
    });

    test('claimed but fully paid goes back to Bucket', () {
      expect(CollectionActivityController.isClaimedOpen(item('a', assignedAt: '2026-09-15T08:00:00', balance: 0)), isFalse);
    });
  });

  group('mergeUnique', () {
    test('an id present in both lists is counted once, Activity copy wins', () {
      final stale = item('INV-1');
      final fresh = item('INV-1', assignedAt: '2026-09-15T08:00:00', history: [
        CollectionHistoryModel(date: '2026-09-15', collectorName: 'Juan', status: 'Partially Collected', totalCollected: 400),
      ]);
      final merged = CollectionActivityController.mergeUnique([stale, item('INV-2')], [fresh]);

      expect(merged.length, 2);
      final inv1 = merged.singleWhere((i) => i.id == 'INV-1');
      expect(inv1.history.length, 1, reason: 'the activity copy carries the payment');
      final total = merged.fold<double>(0, (p, i) => p + i.history.fold<double>(0, (q, h) => q + h.totalCollected));
      expect(total, 400, reason: 'payment counted exactly once');
    });
  });
}
