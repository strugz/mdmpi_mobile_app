import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/data/models/directory_user.dart';
import 'package:mdmpi_mobile_app/data/models/role_model.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/controllers/signup_controller.dart';

/// The sign-up form follows the department: its roles, and for Collection
/// the Head (`HeadKey` / `HeadName`).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SignupController c;

  setUp(() {
    // Not put in GetX, so onInit (Firebase repositories) never runs.
    c = SignupController();
    c.roles.value = [
      for (final r in [
        'Viewer',
        'Request',
        'Release',
        'Courier',
        'HD',
        'CollectionPoster',
        'CollectionHead'
      ])
        RoleModel(id: r, role: r, status: false),
    ];
  });

  List<String> names() => c.filteredRoles.map((r) => r.role).toList();

  test('no roles until a department is picked', () {
    expect(names(), isEmpty);
  });

  test('Logistics gets the Logistics roles only', () {
    c.onDepartmentChanged('Logistics');
    expect(c.department.text, 'Logistics');
    expect(names(), ['Viewer', 'Request', 'Release', 'Courier', 'HD']);
  });

  test('Collection gets the Logistics roles plus its own', () {
    c.onDepartmentChanged('Collection');
    expect(names(), contains('CollectionPoster'));
    expect(names(), contains('CollectionHead'));
    expect(names(), contains('Request'));
    expect(c.isCollection, isTrue);
  });

  test('changing department clears the chosen roles and the Head', () {
    c.onDepartmentChanged('Collection');
    c.roles.value.firstWhere((r) => r.role == 'CollectionHead').status = true;
    c.updateRole('CollectionHead');
    c.selectHead(const DirectoryUser(key: 'GSC', name: 'Gemalee S Chua'));
    expect(c.selectedRole.text, 'CollectionHead');
    expect(c.headKey.value, 'GSC');

    c.onDepartmentChanged('Logistics');
    expect(c.selectedRole.text, isEmpty);
    expect(c.roles.value.any((r) => r.status), isFalse);
    expect(c.headKey.value, isEmpty);
    expect(c.headName.value, isEmpty);
  });

  test('picking the same department again keeps the selection', () {
    c.onDepartmentChanged('Collection');
    c.updateRole('Request');
    c.onDepartmentChanged('Collection');
    expect(c.selectedRole.text, 'Request');
  });

  test('clearForm resets department, roles and Head', () {
    c.onDepartmentChanged('Collection');
    c.updateRole('Request');
    c.selectHead(const DirectoryUser(key: 'GSC', name: 'Gemalee S Chua'));

    c.clearForm();
    expect(c.selectedDepartment.value, isEmpty);
    expect(c.department.text, isEmpty);
    expect(c.selectedRole.text, isEmpty);
    expect(c.headKey.value, isEmpty);
  });

  test('Head search matches name, code or department', () {
    c.headDirectory.assignAll(const [
      DirectoryUser(key: 'GSC', name: 'Gemalee S Chua', department: 'Collection'),
      DirectoryUser(key: 'JCA', name: 'Jay Bryan Abaoag', department: 'IT'),
    ]);
    c.headQuery.value = 'gem';
    expect(c.filteredHeadDirectory.map((u) => u.key), ['GSC']);
    c.headQuery.value = 'jca';
    expect(c.filteredHeadDirectory.map((u) => u.key), ['JCA']);
    c.headQuery.value = 'collection';
    expect(c.filteredHeadDirectory.map((u) => u.key), ['GSC']);
    c.headQuery.value = '';
    expect(c.filteredHeadDirectory, hasLength(2));
  });
}
