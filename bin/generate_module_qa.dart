import 'dart:io';

/// Simple generator to create a module-specific QA addendum and seed test cases.
/// Usage (PowerShell):
///   dart run bin/generate_module_qa.dart --name "Request Transport V2" --area Logistics --flag request_transport_v2 --routes "/request-transport" --owner "Team Logistics"
///
/// Outputs:
///   docs/modules/<slug>/README.md (module QA addendum)
///   docs/modules/<slug>/test_cases_<slug>.csv (seeded cases)
///   Optionally appends to docs/test_cases_index.csv with --append
void main(List<String> args) async {
  final params = _Args.parse(args);
  if (!params.isValid) {
    _printHelp();
    exit(1);
  }
  final slug = _slugify(params.name);
  final outDir = Directory('docs/modules/$slug');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  // Generate README.md from template
  final templatePath = 'docs/templates/module_qa_template.md';
  final template = await File(templatePath).readAsString();
  final rendered = template
      .replaceAll('{MODULE_NAME}', params.name)
      .replaceAll('{AREA}', params.area)
      .replaceAll('{ROUTES}', params.routes)
      .replaceAll('{FLAG}', params.flag ?? 'n/a')
      .replaceAll('{OWNER}', params.owner ?? 'n/a')
      .replaceAll('{RISKS}', params.risks ?? '-')
      .replaceAll('{DATA_DEPENDENCIES}', params.dataDeps ?? '-')
      .replaceAll('{MODULE_SLUG}', slug);

  File('docs/modules/$slug/README.md').writeAsStringSync(rendered);

  // Seed test cases CSV
  final csv = StringBuffer()
    ..writeln('ID,Area,Title,Preconditions,Steps,Expected Result');

  final idPrefix = _idPrefix(params.area, slug);
  final baseCases = _seedCases(idPrefix);
  for (final row in baseCases) {
    csv.writeln(row);
  }
  File('docs/modules/$slug/test_cases_$slug.csv').writeAsStringSync(csv.toString());

  if (params.appendIndex) {
    final indexFile = File('docs/test_cases_index.csv');
    if (!indexFile.existsSync()) {
      stderr.writeln('docs/test_cases_index.csv not found; skipping append.');
    } else {
      await indexFile.writeAsString('\n${baseCases.join('\n')}\n', mode: FileMode.append);
      stdout.writeln('Appended ${baseCases.length} rows to docs/test_cases_index.csv');
    }
  }

  stdout.writeln('Generated module QA for "$slug" at ${outDir.path}');
}

class _Args {
  final String name;
  final String area;
  final String routes;
  final String? flag;
  final String? owner;
  final String? risks;
  final String? dataDeps;
  final bool appendIndex;

  _Args({
    required this.name,
    required this.area,
    required this.routes,
    required this.flag,
    required this.owner,
    required this.risks,
    required this.dataDeps,
    required this.appendIndex,
  });

  bool get isValid => name.isNotEmpty && area.isNotEmpty;

  static _Args parse(List<String> args) {
    String name = '';
    String area = '';
    String routes = '';
    String? flag;
    String? owner;
    String? risks;
    String? dataDeps;
    bool append = false;

    for (var i = 0; i < args.length; i++) {
      final a = args[i];
      if (a == '--name') name = args[++i];
      else if (a == '--area') area = args[++i];
      else if (a == '--routes') routes = args[++i];
      else if (a == '--flag') flag = args[++i];
      else if (a == '--owner') owner = args[++i];
      else if (a == '--risks') risks = args[++i];
      else if (a == '--data') dataDeps = args[++i];
      else if (a == '--append') append = true;
    }
    return _Args(
      name: name,
      area: area,
      routes: routes,
      flag: flag,
      owner: owner,
      risks: risks,
      dataDeps: dataDeps,
      appendIndex: append,
    );
  }
}

String _slugify(String input) {
  var s = input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  s = s.replaceAll(RegExp(r'-+'), '-');
  s = s.replaceAll(RegExp(r'^-'), '');
  s = s.replaceAll(RegExp(r'-$'), '');
  return s;
}

String _idPrefix(String area, String slug) {
  final a = area.trim().toUpperCase();
  if (a.startsWith('AUTH')) return 'AUTH';
  if (a.startsWith('ONB')) return 'ONB';
  if (a.startsWith('LOG')) return 'LOG';
  if (a.startsWith('TRN')) return 'TRN';
  if (a.startsWith('MAP')) return 'MAP';
  if (a.startsWith('NOTI')) return 'NOTI';
  if (a.startsWith('PERM')) return 'PERM';
  if (a.startsWith('WS')) return 'WS';
  if (a.startsWith('BG')) return 'BG';
  if (a.startsWith('SMS')) return 'SMS';
  if (a.startsWith('DB')) return 'DB';
  if (a.startsWith('SEC')) return 'SEC';
  if (a.startsWith('ACC')) return 'ACC';
  if (a.startsWith('PERF')) return 'PERF';
  return a.substring(0, a.length >= 3 ? 3 : a.length);
}

List<String> _seedCases(String prefix) {
  // Provide 6 common cases to start; edit as needed per module.
  return <String>[
    '${prefix}-M01,Module,Happy path flow,,,Works end-to-end without errors',
    '${prefix}-M02,Module,Validation error states,,,Inline messages shown; submit blocked',
    '${prefix}-M03,Module,Offline flow,,,Queued and syncs on reconnect',
    '${prefix}-M04,Module,Permission denied path,,,Graceful fallback with guidance',
    '${prefix}-M05,Module,Notification/Realtime updates,,,Updates reflected correctly',
    '${prefix}-M06,Module,Performance on low-end device,,,Within acceptable limits',
  ];
}

void _printHelp() {
  stdout.writeln('Usage: dart run bin/generate_module_qa.dart --name "<Module Name>" --area <Area> [--flag <flag>] [--routes "<route1,route2>"] [--owner "<Owner>"] [--risks "<risks>"] [--data "<data deps>"] [--append]');
}
