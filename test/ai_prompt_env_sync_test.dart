import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/repositories/inventory/inventory_item_repository.dart';

/// The OCR prompt lives in two places: the `AI_PROMPT` sample in
/// `.env.example`, and [InventoryItemRepository.defaultAnalysisPrompt] which
/// is used when `.env` sets no override.
///
/// The `.env.example` copy has to survive dotenv's own escaping rules, and a
/// stray real newline there silently truncates the prompt. These tests parse
/// the file with the real parser and compare the result to the constant, so
/// the two cannot drift and the escaping cannot regress.
void main() {
  late String envPromptRaw;
  late Map<String, String> parsed;

  setUpAll(() {
    final file = File('.env.example');
    expect(file.existsSync(), isTrue,
        reason: 'run this test from the package root');

    final lines = file.readAsLinesSync();
    final matches = lines.where((l) => l.startsWith('AI_PROMPT=')).toList();
    expect(matches.length, 1, reason: 'expected exactly one AI_PROMPT line');
    envPromptRaw = matches.single;

    parsed = const Parser().parse(lines);
  });

  test('AI_PROMPT occupies a single line', () {
    // dotenv reads line by line, so a value broken across lines is truncated
    // at the first newline without any error.
    expect(envPromptRaw.contains('\n'), isFalse);
    expect(envPromptRaw.contains('\r'), isFalse);
    expect(envPromptRaw.endsWith('"'), isTrue,
        reason: 'the quoted value must close on the same line');
  });

  test('AI_PROMPT parses to the in-code default prompt exactly', () {
    expect(parsed['AI_PROMPT'], InventoryItemRepository.defaultAnalysisPrompt);
  });

  test('the parsed prompt names every key the item parser reads', () {
    final prompt = parsed['AI_PROMPT']!;

    for (final key in [
      'Item Code',
      'Description',
      'Qty',
      'Unit',
      'Part No.',
      'Serial No.',
      'PTN',
      'batch',
      'Batch/Serial #',
      'Batch Quantity',
      'Expiry Date',
    ]) {
      expect(prompt, contains('"$key"'), reason: 'prompt must name "$key"');
    }
  });

  test('the parsed prompt refuses to extract remarks', () {
    final prompt = parsed['AI_PROMPT']!;

    // The mobile client does not carry remarks; the column stays in the
    // database for the backend to populate. The word still appears in the
    // instruction telling the model to skip it, so assert on the places that
    // would actually make it extract one: the key list and the examples.
    expect(prompt, contains('Do NOT extract the REMARKS column'));
    expect(prompt, isNot(contains('"Remarks":')),
        reason: 'no example may show a Remarks value');
    expect(prompt, isNot(contains('"Remarks", "batch"')),
        reason: 'Remarks must not be in the required key list');
    expect(prompt, isNot(contains('REMARKS to "Remarks"')),
        reason: 'the column mapping must be gone');
  });

  test('the parsed prompt keeps both document types and the Warehouse rule',
      () {
    final prompt = parsed['AI_PROMPT']!;

    // Rules that were load-bearing in the original delivery-receipt prompt.
    expect(prompt, contains('Warehouse'));
    expect(prompt, contains('Stock Issue Slip'));
    expect(prompt, contains('delivery receipt'));
    expect(prompt, contains('NOTHING FOLLOWS'));
  });
}
