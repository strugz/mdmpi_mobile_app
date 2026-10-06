import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/upload_comparison.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

StandardDeliveryModel _r({
  String status = 'Item Prepared',
  String date = '2026-09-24',
  String preparedAt = '',
  String driver = '',
  String trip = '',
  String vehicle = '',
  int? mobileId,
}) =>
    StandardDeliveryModel(
      id: '2026090145',
      clientId: 'c',
      shippingMethod: 'Land',
      deliveryTerms: 'Full',
      deliveryDate: date,
      preference: 'Medium',
      status: status,
      requestBy: 'MMA',
      createdBy: 'AMG',
      documentReference: const [],
      client: ClientModel.empty(),
      createdAt: '2026-09-17 08:54:45',
      itemPreparedAt: preparedAt,
      deliveredBy: driver,
      tripTicketNumber: trip,
      mobileName: vehicle,
      mobileID: mobileId,
    );

ComparisonField _field(List<ComparisonField> fields, String label) =>
    fields.firstWhere((f) => f.label == label);

void main() {
  test('flags the status and the other fields that differ', () {
    final fields = BUploadComparison.fields(
      _r(status: 'Item Prepared', driver: 'BPT', trip: '01019'),
      _r(status: 'Delivered', driver: 'CMA', trip: '01019'),
    );

    expect(_field(fields, 'Status').differs, isTrue);
    expect(_field(fields, 'Driver').differs, isTrue);
    expect(_field(fields, 'Driver').phone, 'BPT');
    expect(_field(fields, 'Driver').server, 'CMA');
    expect(_field(fields, 'Trip ticket').differs, isFalse);
  });

  test('stamps match to the second, whatever the format', () {
    final fields = BUploadComparison.fields(
      _r(preparedAt: '2026-09-17 09:07:21.149665'),
      _r(preparedAt: '2026-09-17T09:07:21'),
    );
    expect(_field(fields, 'Preparation started').differs, isFalse);

    final moved = BUploadComparison.fields(
      _r(preparedAt: '2026-09-17 09:07:21'),
      _r(preparedAt: '2026-09-24 08:36:19'),
    );
    expect(_field(moved, 'Preparation started').differs, isTrue);
  });

  test('dates match by day; case and spacing are ignored', () {
    final fields = BUploadComparison.fields(
      _r(date: '2026-09-24', status: 'Getting supplies ready'),
      _r(date: '2026-09-24T00:00:00', status: ' Getting Supplies Ready '),
    );
    expect(_field(fields, 'Delivery date').differs, isFalse);
    expect(_field(fields, 'Status').differs, isFalse);
  });

  test('a value on one side only is a difference', () {
    final fields = BUploadComparison.fields(_r(trip: '01019'), _r(trip: ''));
    expect(_field(fields, 'Trip ticket').differs, isTrue);
    expect(_field(fields, 'Receiver').differs, isFalse);
  });

  test('vehicle falls back to its ID when the name is missing', () {
    final fields =
        BUploadComparison.fields(_r(mobileId: 1), _r(vehicle: 'Vehicle 1'));
    expect(_field(fields, 'Vehicle').phone, 'Vehicle 1');
    expect(_field(fields, 'Vehicle').differs, isFalse);
  });

  test('with no server copy nothing is flagged', () {
    final fields = BUploadComparison.fields(_r(driver: 'BPT'), null);
    expect(fields.any((f) => f.differs), isFalse);
    expect(fields.every((f) => f.server.isEmpty), isTrue);
  });
}
