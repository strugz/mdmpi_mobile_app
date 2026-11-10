import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/delivery_document_type.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/scan_form_target.dart';

/// Scan first: which forms a scanned document may open, by its type and the
/// user's role (decision 2026-10-15).
void main() {
  const request = 'Request';
  const requestAndHd = 'Request, HD';
  const courier = 'Courier';

  test('each scan form maps to its app category and back', () {
    for (final form in DeliveryRequestForm.values) {
      expect(ScanFormTarget.formFor(ScanFormTarget.categoryFor(form)), form);
    }
    expect(ScanFormTarget.categoryFor(DeliveryRequestForm.airSea),
        FormCategoryType.airSeaHd, reason: '"Air/sea" is Air / Sea / Land HD');
    expect(ScanFormTarget.formFor(FormCategoryType.pickUp), isNull);
    expect(ScanFormTarget.formFor(FormCategoryType.stockReceive), isNull);
  });

  test('roles follow the Request screen + button', () {
    expect(ScanFormTarget.canCreate(DeliveryRequestForm.standardDelivery, request), isTrue);
    expect(ScanFormTarget.canCreate(DeliveryRequestForm.airSea, request), isFalse);
    expect(ScanFormTarget.canCreate(DeliveryRequestForm.airSea, requestAndHd), isTrue);
    expect(ScanFormTarget.canCreate(DeliveryRequestForm.hotlineDirect, courier), isTrue);
    expect(ScanFormTarget.canCreate(DeliveryRequestForm.standardDelivery, courier), isFalse);
    expect(ScanFormTarget.canScanAny(''), isFalse);
    expect(ScanFormTarget.canScanAny(courier), isTrue);
  });

  test('a Sales Invoice offers Standard Delivery and Air/Sea/Land; HD only with the HD role',
      () {
    expect(ScanFormTarget.choicesFor(DeliveryDocumentType.salesInvoice, request), [
      DeliveryRequestForm.standardDelivery,
      DeliveryRequestForm.airSeaLand,
    ]);
    expect(ScanFormTarget.choicesFor(DeliveryDocumentType.salesInvoice, requestAndHd), [
      DeliveryRequestForm.standardDelivery,
      DeliveryRequestForm.airSeaLand,
      DeliveryRequestForm.airSea,
    ]);
  });

  test('single-form documents and couriers', () {
    expect(ScanFormTarget.choicesFor(DeliveryDocumentType.returnPullOutSlip, request),
        [DeliveryRequestForm.pullOut]);
    expect(ScanFormTarget.choicesFor(DeliveryDocumentType.reagentsIssueSlip, courier),
        [DeliveryRequestForm.hotlineDirect]);
    expect(ScanFormTarget.choicesFor(DeliveryDocumentType.inventoryTransfer, courier),
        isEmpty, reason: 'a courier creates Hotline Direct only');
  });

  test('an unreadable title offers every form the user may create', () {
    expect(ScanFormTarget.choicesFor(DeliveryDocumentType.unknown, request), [
      DeliveryRequestForm.standardDelivery,
      DeliveryRequestForm.airSeaLand,
      DeliveryRequestForm.hotlineDirect,
      DeliveryRequestForm.pullOut,
    ]);
  });

  test('every form takes items (Air/Sea since 2026-10-15)', () {
    expect(ScanFormTarget.takesItems(DeliveryRequestForm.airSeaLand), isTrue,
        reason: 'Air/Sea items, plan LOGISTICS_AIR_SEA_ITEMS_PLAN.md');
    expect(ScanFormTarget.takesItems(DeliveryRequestForm.airSea), isTrue);
    expect(ScanFormTarget.takesItems(DeliveryRequestForm.pullOut), isTrue);
    expect(ScanFormTarget.takesItems(DeliveryRequestForm.hotlineDirect), isTrue);
  });
}
