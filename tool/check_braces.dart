import 'dart:io';

void main(List<String> args) {
  final path = args.isNotEmpty ? args[0] : 'lib/features/logistics/models/pull_out_model.dart';
  final f = File(path);
  if (!f.existsSync()) {
    print('File not found: $path');
    exit(2);
  }
  final text = f.readAsStringSync();
  final open = RegExp('{').allMatches(text).length;
  final close = RegExp('}').allMatches(text).length;
  print('Open braces: $open');
  print('Close braces: $close');
  if (open != close) {
    print('Mismatch: ${open - close}');
    // print snippet around copyWith
    final idx = text.indexOf('copyWith(');
    if (idx != -1) {
      final start = idx - 200 < 0 ? 0 : idx - 200;
      final end = idx + 200 > text.length ? text.length : idx + 200;
      print('Context:\n' + text.substring(start, end));
    }
    exit(3);
  } else {
    print('Braces balanced.');
  }
}

