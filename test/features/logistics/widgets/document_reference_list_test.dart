import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/b_document_reference_list.dart';

const refs = [
  'DRNo.:690013618',
  'SINo.:700013619',
  'DRNo.:690013615',
  'PONo.:2026-07-0992',
  'SINo.:700013615',
  'PONo.:2026-08-1060',
  'DRNo.:690013620',
  'PONo.:2026-08-1057',
  ' DRNo.:690013618 ', // duplicate with whitespace
  '',
  'LOOSE-REF',
];

Widget host(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  test('group() de-duplicates, trims and groups by prefix in first-seen order',
      () {
    final groups = DocumentReferenceList.group(refs);

    expect(groups.keys.toList(), ['DRNo.', 'SINo.', 'PONo.', '']);
    expect(groups['DRNo.']!.map((r) => r.value).toList(),
        ['690013618', '690013615', '690013620']);
    expect(groups['PONo.']!.first.full, 'PONo.:2026-07-0992');
    expect(groups['']!.single.value, 'LOOSE-REF');
  });

  testWidgets('folds past the limit and expands on "Show all"', (tester) async {
    await tester.pumpWidget(host(const DocumentReferenceList(
      documentReferences: refs,
      textColor: Colors.black,
      collapsedLimit: 6,
    )));

    // 9 unique refs, budget 6 taken group by group: DR×3, SI×2, PO×1 shown;
    // the remaining POs and the loose reference are folded away.
    expect(find.text('Show all 9'), findsOneWidget);
    expect(find.text('690013620'), findsOneWidget);
    expect(find.text('2026-07-0992'), findsOneWidget);
    expect(find.text('2026-08-1060'), findsNothing);
    expect(find.text('LOOSE-REF'), findsNothing);
    expect(find.text('Copy all'), findsOneWidget);

    await tester.tap(find.text('Show all 9'));
    await tester.pumpAndSettle();

    expect(find.text('2026-08-1060'), findsOneWidget);
    expect(find.text('LOOSE-REF'), findsOneWidget);
    expect(find.text('Show less'), findsOneWidget);
  });

  testWidgets('short lists show no fold control and short prefixes',
      (tester) async {
    await tester.pumpWidget(host(const DocumentReferenceList(
      documentReferences: ['DRNo.:1', 'SINo.:2'],
      textColor: Colors.black,
    )));

    expect(find.textContaining('Show all'), findsNothing);
    expect(find.text('DR'), findsOneWidget);
    expect(find.text('SI'), findsOneWidget);
    expect(find.text('Copy all'), findsOneWidget);
  });

  testWidgets('a single reference renders without any controls', (tester) async {
    await tester.pumpWidget(host(const DocumentReferenceList(
      documentReferences: ['DRNo.:1'],
      textColor: Colors.black,
    )));

    expect(find.text('1'), findsOneWidget);
    expect(find.text('Copy all'), findsNothing);
  });
}
