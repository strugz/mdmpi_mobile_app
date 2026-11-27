import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_extractor.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/client_header_extractor.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/delivery_document_type.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/ocr_read_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/one_scan_reference_patterns.dart';

/// Developer tool: what the last scan read, by rows or as raw lines, with a
/// search. Opened from "Check the scan" (debug builds) and from Settings >
/// Developer Tools > Dump OCR lines.
class OcrReadController extends GetxController {
  OcrReadController(List<OcrLine> lines)
      : _rows = OcrReadText.rows(lines),
        _lines = OcrReadText.lines(lines),
        documentType = DeliveryDocumentType.detect(lines),
        commentRows = ClientHeaderExtractor.commentRows(lines) {
    references = OneScanReferencePatterns.forDocument(
        lines, DocumentReferenceExtractor(), documentType);
  }

  final List<OcrReadEntry> _rows;
  final List<OcrReadEntry> _lines;
  final DeliveryDocumentType documentType;
  final List<String> commentRows;
  late final List<String> references;

  final RxString query = ''.obs;
  final RxBool byRows = true.obs;

  int get total => byRows.value ? _rows.length : _lines.length;

  List<OcrReadEntry> get shown =>
      OcrReadText.search(byRows.value ? _rows : _lines, query.value);

  Future<void> copyShown() async {
    await Clipboard.setData(ClipboardData(text: OcrReadText.asText(shown)));
    BLoaders.customToast(message: 'Copied ${shown.length} entries');
  }
}

class OcrReadPage extends StatelessWidget {
  const OcrReadPage({super.key, required this.lines});

  final List<OcrLine> lines;

  @override
  Widget build(BuildContext context) {
    final c = Get.put(OcrReadController(lines));
    final theme = Theme.of(context);
    return Scaffold(
      appBar: BAppBar(
        title: const Text('OCR read'),
        showBackArrow: true,
        actions: [
          IconButton(
            tooltip: 'Copy what is shown',
            icon: const Icon(Iconsax.copy),
            onPressed: c.copyShown,
          ),
        ],
      ),
      body: lines.isEmpty
          ? const Center(child: Text('No scan yet. Scan a document first.'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      BSizes.md, BSizes.sm, BSizes.md, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Document: ${c.documentType.label}',
                          style: theme.textTheme.bodySmall),
                      Text(
                          'References: ${c.references.isEmpty ? 'none' : c.references.join(', ')}',
                          style: theme.textTheme.bodySmall),
                      if (c.commentRows.isNotEmpty)
                        Text('Under Comments: ${c.commentRows.join(' / ')}',
                            style: theme.textTheme.bodySmall),
                      const SizedBox(height: BSizes.sm),
                      TextField(
                        key: const Key('ocrReadSearch'),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Iconsax.search_normal),
                          hintText: 'Search what was read, e.g. GI No',
                          isDense: true,
                        ),
                        onChanged: (v) => c.query.value = v,
                      ),
                      const SizedBox(height: BSizes.sm),
                      Obx(() => Row(
                            children: [
                              ChoiceChip(
                                label: const Text('By rows'),
                                selected: c.byRows.value,
                                onSelected: (_) => c.byRows.value = true,
                              ),
                              const SizedBox(width: BSizes.sm),
                              ChoiceChip(
                                label: const Text('Raw lines'),
                                selected: !c.byRows.value,
                                onSelected: (_) => c.byRows.value = false,
                              ),
                              const Spacer(),
                              Text('${c.shown.length} of ${c.total}',
                                  style: theme.textTheme.bodySmall),
                            ],
                          )),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: Obx(() {
                    final shown = c.shown;
                    return ListView.separated(
                      padding: EdgeInsets.only(
                          bottom: BSizes.md +
                              MediaQuery.of(context).padding.bottom),
                      itemCount: shown.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (_, i) => ListTile(
                        dense: true,
                        title: SelectableText(shown[i].text),
                        subtitle: Text(shown[i].where),
                      ),
                    );
                  }),
                ),
              ],
            ),
    );
  }
}
