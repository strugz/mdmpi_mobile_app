import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/data/models/department_model.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/controllers/signup_controller.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/pages/signup/widgets/department_fields/collection_signup_fields.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/pages/signup/widgets/signup_form.dart';

/// The department-aware form only adds: every field from before is still
/// there for every department, and Collection alone gets the Head.
void main() {
  late SignupController controller;

  setUp(() {
    controller = Get.put(SignupController());
    controller.departments.value = [
      for (final d in ['Logistics', 'Collection', 'Service', 'InHouse'])
        DepartmentModel(id: d, department: d, status: false),
    ];
  });

  tearDown(Get.reset);

  Future<void> pumpForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GetMaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: SignUpForm()))));
    await tester.pump();
  }

  void expectOriginalFields() {
    for (final label in [
      BTexts.firstname,
      BTexts.lastname,
      BTexts.username,
      BTexts.email,
      BTexts.initial,
      'Department',
      'Role',
      BTexts.mobile,
      BTexts.password,
    ]) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(find.text(BTexts.createAccount), findsOneWidget);
  }

  testWidgets('no department: every original field, no Collection section',
      (tester) async {
    await pumpForm(tester);
    expectOriginalFields();
    expect(find.text('Select a department first'), findsOneWidget);
    expect(find.byType(CollectionSignupFields), findsNothing);
  });

  for (final dept in ['Logistics', 'Service', 'InHouse']) {
    testWidgets('$dept: every original field, no Collection section',
        (tester) async {
      await pumpForm(tester);
      controller.onDepartmentChanged(dept);
      await tester.pump();
      expectOriginalFields();
      expect(find.byType(CollectionSignupFields), findsNothing);
    });
  }

  testWidgets('Collection: every original field plus the Head', (tester) async {
    await pumpForm(tester);
    controller.onDepartmentChanged('Collection');
    await tester.pump();
    expectOriginalFields();
    expect(find.byType(CollectionSignupFields), findsOneWidget);
    expect(find.text('My Head (optional)'), findsOneWidget);
  });
}
