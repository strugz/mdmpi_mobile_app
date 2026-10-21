import 'dart:io';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mdmpi_mobile_app/base/utils/b_client_address.dart';
import 'package:mdmpi_mobile_app/base/utils/b_document_scanner.dart';
import 'package:mdmpi_mobile_app/base/utils/b_name_normalizer.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_permission_service.dart';
import 'package:mdmpi_mobile_app/data/repositories/client/client_alias_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/delivery_document_type.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/scan_form_target.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/delivery_document_scan_result.dart';
import 'package:mdmpi_mobile_app/features/logistics/services/i_delivery_document_scan_service.dart';

/// What [DeliveryDocumentScanController.applyToForm] changed.
class OneScanApplied {
  const OneScanApplied({
    required this.clientSet,
    required this.referencesAdded,
    required this.itemsAdded,
    this.itemsSkipped = false,
    this.target,
  });

  final bool clientSet;
  final int referencesAdded;
  final int itemsAdded;

  /// Items were read but the target form does not save them (Air/Sea).
  final bool itemsSkipped;

  /// The form the scan went to.
  final DeliveryRequestForm? target;
}

/// State of one "Scan Document" run on the Standard Delivery form
/// (plan §3, §5 step 14). The form's own controller only gains two small
/// entry points; the scan logic lives here.
/// Where a one-scan page comes from.
enum DocumentScanSource {
  /// Google's document scanner: crops, straightens and flattens the page
  /// (camera, or a gallery photo imported inside it). Android only.
  scanner,

  /// A plain camera photo, read as taken.
  camera,

  /// A gallery photo, read as it is.
  gallery,
}

class DeliveryDocumentScanController extends GetxController {
  DeliveryDocumentScanController({
    required IDeliveryDocumentScanService service,
    required ClientAliasRepository aliases,
    IPermissionService? permissions,
    Future<File?> Function(ImageSource source)? pickImage,
    Future<List<File>?> Function()? documentScan,
  })  : _service = service,
        _aliases = aliases,
        _permissions = permissions,
        _pickImage = pickImage,
        _documentScan = documentScan;

  final IDeliveryDocumentScanService _service;
  final ClientAliasRepository _aliases;
  final IPermissionService? _permissions;
  final Future<File?> Function(ImageSource source)? _pickImage;
  final Future<List<File>?> Function()? _documentScan;

  final RxBool isScanning = false.obs;
  final RxnString error = RxnString();
  final Rxn<DeliveryDocumentScanResult> result = Rxn<DeliveryDocumentScanResult>();

  /// The client the user tapped, with the address rule applied (§4.4a).
  final Rxn<ClientModel> confirmedClient = Rxn<ClientModel>();

  /// True when [confirmedClient]'s address came from the scanned document.
  final RxBool addressFromScan = false.obs;

  /// "Skip client": apply references and items, leave the client alone.
  final RxBool skipClient = false.obs;

  /// References still ticked on the review sheet.
  final RxSet<String> selectedReferences = <String>{}.obs;

  final RxBool includeItems = true.obs;

  /// The request form the scan fills: fixed when scanning from an open
  /// form, chosen on the review sheet when scanning from the Request screen.
  final Rxn<DeliveryRequestForm> target = Rxn<DeliveryRequestForm>();

  /// Scan first: the forms this document can open for the user. Empty when
  /// the form was fixed by the open form.
  final RxList<DeliveryRequestForm> targetChoices = <DeliveryRequestForm>[].obs;

  /// Whether the user picks the form on the review sheet (scan first).
  final RxBool choosesTarget = false.obs;

  /// "An Inventory Transfer is for … not Standard Delivery.", or null when
  /// the document belongs on the target form (or its title was not read).
  String? get documentWarning {
    final form = target.value;
    if (form == null) return null;
    return result.value?.documentType.mismatchWarning(form);
  }

  /// Apply is enabled once there is a form, and a client is confirmed or
  /// skipped (§3).
  bool get canApply =>
      result.value != null &&
      target.value != null &&
      (confirmedClient.value != null || skipClient.value);

  void chooseTarget(DeliveryRequestForm form) => target.value = form;

  @override
  void onClose() {
    _service.clearCache();
    super.onClose();
  }

  /// Asks for the permission and opens the camera or gallery. Null when the
  /// user cancelled or it failed ([error] says why).
  Future<File?> pickFrom(ImageSource source) async {
    error.value = null;
    try {
      final permissions = _permissions;
      if (permissions != null) {
        final granted = await permissions.requireForFeature(
          source == ImageSource.camera
              ? PermissionType.camera
              : PermissionType.storage,
          featureName: 'Scan document',
        );
        if (!granted.granted) return null;
      }
      return await (_pickImage ?? _defaultPick)(source);
    } catch (e, st) {
      logDebug('[OneScan] pick failed: $e\n$st');
      error.value = 'Could not open the ${source.name}: $e';
      return null;
    }
  }

  /// The page from [source]. [DocumentScanSource.scanner] runs Google's
  /// document scanner, which crops, straightens and flattens the page (and
  /// can import a gallery photo the same way) before it is read; where the
  /// scanner cannot run, a plain camera photo instead. Null when the user
  /// cancelled or it failed ([error] says why).
  Future<File?> pickPage(DocumentScanSource source) async {
    switch (source) {
      case DocumentScanSource.camera:
        return pickFrom(ImageSource.camera);
      case DocumentScanSource.gallery:
        return pickFrom(ImageSource.gallery);
      case DocumentScanSource.scanner:
        error.value = null;
        final pages = await (_documentScan ?? _defaultDocumentScan)();
        if (pages == null) {
          logDebug('[OneScan] document scanner unavailable; using the camera');
          return pickFrom(ImageSource.camera);
        }
        return pages.isEmpty ? null : pages.first;
    }
  }

  static Future<List<File>?> _defaultDocumentScan() =>
      BDocumentScanner.scan(galleryImport: true);

  static Future<File?> _defaultPick(ImageSource source) async {
    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 90);
    return picked == null ? null : File(picked.path);
  }

  /// Reads [file] and resets the review choices. With [fixedTarget] (an open
  /// form) the scan fills that form; without it the user picks one of the
  /// forms the document belongs to and [role] may create.
  Future<bool> scanFile(
    File file, {
    DeliveryRequestForm? fixedTarget = DeliveryRequestForm.standardDelivery,
    String role = '',
  }) async {
    isScanning.value = true;
    error.value = null;
    try {
      final scanned = await _service.scan(file);
      if (scanned.isFailure) {
        error.value = scanned.error;
        return false;
      }
      final value = scanned.value;
      result.value = value;
      confirmedClient.value = null;
      addressFromScan.value = false;
      skipClient.value = false;
      selectedReferences
        ..clear()
        ..addAll(value.references);
      includeItems.value = value.items.items.isNotEmpty;
      if (fixedTarget != null) {
        choosesTarget.value = false;
        targetChoices.clear();
        target.value = fixedTarget;
      } else {
        choosesTarget.value = true;
        targetChoices.assignAll(
            ScanFormTarget.choicesFor(value.documentType, role));
        target.value = targetChoices.length == 1 ? targetChoices.first : null;
      }
      return true;
    } finally {
      isScanning.value = false;
    }
  }

  /// The user tapped [client] (from the candidates or the pre-filled
  /// search). Applies the address rule and remembers the scanned name as an
  /// alias for next time.
  Future<void> confirmClient(ClientModel client) async {
    final header = result.value?.header;
    final resolved = BClientAddress.resolve(client.address, header?.address);
    confirmedClient.value = resolved.fromScan
        ? client.copyWith(address: resolved.address)
        : client;
    addressFromScan.value = resolved.fromScan;
    skipClient.value = false;

    final ocrName = header?.name;
    if (ocrName != null && ocrName.trim().isNotEmpty) {
      await _aliases.remember(BNameNormalizer.normalize(ocrName), client.id);
    }
  }

  /// What to pre-fill the client search with: the first distinctive word of
  /// the scanned name (`Galinato`). The search matches by "contains", so the
  /// whole scanned name (`Galinato Clinic and Hospital` vs `GALINATO CLINIC &
  /// HOSPITAL`) would usually find nothing.
  String get searchSeed {
    final name = result.value?.header.name ?? '';
    final tokens = BNameNormalizer.scoringTokens(name);
    if (tokens.isEmpty) return name;
    return tokens.firstWhere((t) => t.length >= 4, orElse: () => tokens.first);
  }

  void chooseSkipClient() {
    confirmedClient.value = null;
    addressFromScan.value = false;
    skipClient.value = true;
  }

  void toggleReference(String reference) {
    if (!selectedReferences.remove(reference)) {
      selectedReferences.add(reference);
    }
  }

  /// Whether applying would replace a different client already on the form,
  /// so the sheet asks "Replace client X with Y?" first.
  bool replacesClientOn(StandardDeliveryController form) {
    final current = form.formState.clientInformation.value;
    final chosen = confirmedClient.value;
    return chosen != null &&
        current != null &&
        !current.isEmpty &&
        current.id != chosen.id;
  }

  /// Puts the confirmed client, the ticked references and the items on the
  /// form. Nothing is saved: the user still taps Create Request.
  OneScanApplied applyToForm(StandardDeliveryController form) {
    final scanned = result.value;
    if (scanned == null) {
      return const OneScanApplied(
          clientSet: false, referencesAdded: 0, itemsAdded: 0);
    }

    var clientSet = false;
    final chosen = confirmedClient.value;
    if (chosen != null && !skipClient.value) {
      form.updateRequestClientInformation(chosen);
      form.formState.scannedFallbackAddress.value = addressFromScan.value
          ? (clientId: chosen.id, address: chosen.address)
          : null;
      clientSet = true;
    }

    final refs = scanned.references
        .where(selectedReferences.contains)
        .toList(growable: false);
    final referencesAdded = form.appendDocumentReferences(refs);

    var itemsAdded = 0;
    final takesItems =
        target.value == null || ScanFormTarget.takesItems(target.value!);
    final itemsSkipped = includeItems.value &&
        scanned.items.items.isNotEmpty &&
        !takesItems;
    if (includeItems.value && scanned.items.items.isNotEmpty && takesItems) {
      form.mergeScannedItems(scanned.items.items);
      itemsAdded = scanned.items.items.length;
    }

    logDebug('[OneScan] applied client=${chosen?.id ?? '-'} '
        'fallbackAddress=${addressFromScan.value} refs=$referencesAdded '
        'items=$itemsAdded');
    return OneScanApplied(
      clientSet: clientSet,
      referencesAdded: referencesAdded,
      itemsAdded: itemsAdded,
      itemsSkipped: itemsSkipped,
      target: target.value,
    );
  }

  /// Clears the last scan (the sheet was cancelled).
  void discard() {
    result.value = null;
    confirmedClient.value = null;
    addressFromScan.value = false;
    skipClient.value = false;
    selectedReferences.clear();
    target.value = null;
    targetChoices.clear();
    choosesTarget.value = false;
  }
}
