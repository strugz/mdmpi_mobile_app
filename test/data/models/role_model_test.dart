import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/models/role_model.dart';

/// Sign-up offers each role per department: a `Departments` tag on the
/// `Roles` doc wins; untagged Collection roles go to Collection only, and
/// every other untagged role to everyone (today's behaviour).
void main() {
  RoleModel role(String name, [List<String> departments = const []]) =>
      RoleModel(id: name, role: name, status: false, departments: departments);

  test('untagged Logistics roles go to every department', () {
    for (final name in ['Viewer', 'Request', 'Release', 'Courier', 'HD']) {
      for (final d in ['Logistics', 'Collection', 'Service', 'InHouse']) {
        expect(role(name).appliesTo(d), isTrue, reason: '$name / $d');
      }
    }
  });

  test('untagged Collection roles go to Collection only', () {
    for (final name in ['CollectionHead', 'CollectionPoster']) {
      expect(role(name).appliesTo('Collection'), isTrue);
      expect(role(name).appliesTo(' collection '), isTrue);
      expect(role(name).appliesTo('Logistics'), isFalse);
      expect(role(name).appliesTo('Service'), isFalse);
    }
  });

  test('a Departments tag wins, case- and space-insensitive', () {
    final r = role('Courier', [' logistics ']);
    expect(r.appliesTo('Logistics'), isTrue);
    expect(r.appliesTo('Collection'), isFalse);
    expect(role('CollectionPoster', ['Collection', 'InHouse']).appliesTo('InHouse'),
        isTrue);
  });

  test('no department, no roles', () {
    expect(role('Viewer').appliesTo(''), isFalse);
    expect(role('Viewer').appliesTo('  '), isFalse);
  });

  test('Departments parses an array or a comma-separated string', () {
    expect(RoleModel.parseDepartments(['Logistics', ' ', 'Collection']),
        ['Logistics', 'Collection']);
    expect(RoleModel.parseDepartments('Logistics, Collection,'),
        ['Logistics', 'Collection']);
    expect(RoleModel.parseDepartments(null), isEmpty);
    expect(RoleModel.parseDepartments(42), isEmpty);
  });

  test('fromJson reads Departments when present and defaults when not', () {
    final tagged = RoleModel.fromJson(
        {'ID': '1', 'Role': 'Courier', 'Departments': ['Logistics']});
    expect(tagged.departments, ['Logistics']);
    expect(tagged.toJson()['Departments'], ['Logistics']);

    final untagged = RoleModel.fromJson({'ID': '2', 'Role': 'Viewer'});
    expect(untagged.departments, isEmpty);
    expect(untagged.toJson().containsKey('Departments'), isFalse);
  });
}
