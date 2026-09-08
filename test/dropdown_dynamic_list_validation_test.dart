import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown_dynamic_list.dart';

void main() {
  final users = [
    {'CNTMNN': '101', 'CNTMCN': 'Genesis Princess E. Montero'},
    {'CNTMNN': '102', 'CNTMCN': 'Jerald R Quines'},
  ];

  Widget buildForm(GlobalKey<FormState> formKey, TextEditingController ctrl) {
    return MaterialApp(
      home: Scaffold(
        body: Form(
          key: formKey,
          child: BDropDownDynamicList(
            controller: ctrl,
            label: 'Requested By',
            dropdownList: users,
            valueKey: 'CNTMNN',
            displayKey: 'CNTMCN',
            enableSearch: true,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please select who requested this'
                : null,
          ),
        ),
      ),
    );
  }

  testWidgets(
      'searchable dropdown passes validation after selecting via dialog',
      (tester) async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController();
    addTearDown(ctrl.dispose);

    await tester.pumpWidget(buildForm(formKey, ctrl));

    // Open the searchable dialog and pick a user.
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Genesis Princess E. Montero').last);
    await tester.pumpAndSettle();

    // Controller holds the id and the label is shown.
    expect(ctrl.text, '101');
    expect(find.text('Genesis Princess E. Montero'), findsOneWidget);

    // Rose's scenario: validate should pass since a user is selected.
    expect(formKey.currentState!.validate(), isTrue,
        reason: 'Validation must pass once a user has been selected');
    await tester.pump();
    expect(find.text('Please select who requested this'), findsNothing);
  });

  testWidgets(
      'error shown after failed validate clears when user re-selects and validates again',
      (tester) async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController();
    addTearDown(ctrl.dispose);

    await tester.pumpWidget(buildForm(formKey, ctrl));

    // Validate with nothing selected -> error appears (expected).
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Please select who requested this'), findsOneWidget);

    // Re-select a user (what Rose did repeatedly).
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jerald R Quines').last);
    await tester.pumpAndSettle();

    // Validation must now pass.
    expect(formKey.currentState!.validate(), isTrue,
        reason: 'Re-selecting a user must satisfy the validator');
    await tester.pump();
    expect(find.text('Please select who requested this'), findsNothing);
  });

  testWidgets('validation still fails when nothing is selected',
      (tester) async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController();
    addTearDown(ctrl.dispose);

    await tester.pumpWidget(buildForm(formKey, ctrl));

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Please select who requested this'), findsOneWidget);
  });
}
