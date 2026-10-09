import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_permission_service.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_status_style.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_validator.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_evaluation.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/reconciliation_controller.dart';

/// Picks one photo; null when the collector backs out.
typedef ReconPhotoPicker = Future<Uint8List?> Function(ImageSource source);

/// Log one step of a case (Steps 2–9 of the process).
///
/// Offers only the steps the rules allow now ([allowedReconActivityTypes]),
/// grouped by who did them, so the collector never picks the actor. A stage
/// step that must wait for an earlier stage shows locked, with the reason.
/// The same check runs again on save; its reason is shown here, not in a
/// snackbar.
class ReconLogActivitySheet extends StatefulWidget {
  const ReconLogActivitySheet({
    super.key,
    required this.view,
    this.pickPhoto,
    this.cameraAvailable,
    this.initialType,
  });

  final ReconCaseView view;

  /// The step to start on (the stage track opens the sheet on its stage).
  final ReconActivityType? initialType;

  /// Tests pass a fake; the app uses [ImagePicker].
  final ReconPhotoPicker? pickPhoto;

  /// Null: the camera only on Android (the Windows build has none).
  final bool? cameraAvailable;

  /// Opens the sheet; true when a step was logged.
  static Future<bool> show(ReconCaseView view,
      {ReconPhotoPicker? pickPhoto,
      bool? cameraAvailable,
      ReconActivityType? initialType}) async {
    final logged = await Get.bottomSheet<bool>(
      ReconLogActivitySheet(
          view: view,
          pickPhoto: pickPhoto,
          cameraAvailable: cameraAvailable,
          initialType: initialType),
      isScrollControlled: true,
      backgroundColor: BCollectionColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(BSizes.borderRadiusLg)),
      ),
    );
    return logged ?? false;
  }

  @override
  State<ReconLogActivitySheet> createState() => _ReconLogActivitySheetState();
}

class _ReconLogActivitySheetState extends State<ReconLogActivitySheet> {
  static final DateFormat _day = DateFormat('yyyy-MM-dd');
  static final DateFormat _shown = DateFormat('MMM d, yyyy');

  ReconActivityType? _type;
  final Set<String> _invoices = {};
  ReconValidationResult? _result;
  final _amount = TextEditingController();
  final _remarks = TextEditingController();
  final _nextAction = TextEditingController();
  DateTime? _due;
  final List<Uint8List> _photos = [];
  String? _error;
  bool _saving = false;

  ReconEvaluation get _eval => widget.view.evaluation;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialType;
    if (initial != null && allowedReconActivityTypes(_eval).contains(initial)) {
      _pick(initial);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _remarks.dispose();
    _nextAction.dispose();
    super.dispose();
  }

  void _pick(ReconActivityType type) {
    setState(() {
      _type = type;
      _error = null;
      _result = null;
      _invoices.clear();
      if (type == ReconActivityType.soaSent) {
        _amount.text = BFormatter.formatPesoCurrency(
                _eval.amountUnderReconciliation,
                includeSymbol: false)
            .trim();
      }
    });
  }

  /// The invoices this step can name, and whether naming them is required.
  List<ReconInvoiceState> get _choices => switch (_type) {
        ReconActivityType.paidClaim => _eval.invoices
            .where((i) =>
                i.status == ReconInvoiceStatus.open ||
                i.status == ReconInvoiceStatus.proofInvalid)
            .toList(),
        ReconActivityType.proofRequested => _eval.invoices
            .where((i) =>
                i.status == ReconInvoiceStatus.claimedPaid && !i.proofPending)
            .toList(),
        ReconActivityType.proofProvided =>
          _eval.invoices.where((i) => !i.status.isSettled).toList(),
        ReconActivityType.proofValidated =>
          _eval.invoices.where((i) => i.proofPending).toList(),
        ReconActivityType.documentRequested ||
        ReconActivityType.documentProvided =>
          _eval.openInvoices,
        _ => const [],
      };

  bool get _mustNameInvoices => _type == ReconActivityType.paidClaim;

  bool get _takesPhotos =>
      _type != null && !_type!.isLifecycle && _type != ReconActivityType.note;

  Future<void> _addPhoto(ImageSource source) async {
    final picker = widget.pickPhoto ?? _defaultPick;
    final bytes = await picker(source);
    if (bytes == null || !mounted) return;
    setState(() => _photos.add(bytes));
  }

  static Future<Uint8List?> _defaultPick(ImageSource source) async {
    if (source == ImageSource.camera &&
        Get.isRegistered<IPermissionService>()) {
      final permission = await Get.find<IPermissionService>().requireForFeature(
          PermissionType.camera,
          featureName: 'Reconciliation photo');
      if (!permission.granted) return null;
    }
    final picked = await ImagePicker()
        .pickImage(source: source, imageQuality: 70, maxWidth: 1600);
    return picked?.readAsBytes();
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? now.add(const Duration(days: 3)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _due = picked);
  }

  Future<void> _save() async {
    final type = _type;
    if (type == null) {
      setState(() => _error = 'Choose what happened.');
      return;
    }
    final draft = ReconActivityDraft(
        type: type,
        invoiceNos: _invoices.toList(),
        validationResult: _result,
        attachmentCount: _photos.length);
    final allowed = canAppendReconActivity(_eval, draft);
    if (allowed.isFailure) {
      setState(() => _error = allowed.error);
      return;
    }
    if (type.isLifecycle && !await _confirmEnd(type)) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    final r = await ReconciliationController.instance.logActivity(
      caseId: widget.view.caseId,
      type: type,
      invoiceNos: _invoices.toList(),
      remarks: _remarks.text,
      amount: type == ReconActivityType.soaSent
          ? BFormatter.parseAmount(_amount.text)
          : null,
      validationResult: _result,
      nextAction: _nextAction.text,
      nextActionDueDate: _due == null ? null : _day.format(_due!),
      photos: _photos,
    );
    if (!mounted) return;
    if (r.isSuccess) {
      Get.back(result: true);
    } else {
      setState(() {
        _saving = false;
        _error = r.error;
      });
    }
  }

  Future<bool> _confirmEnd(ReconActivityType type) async {
    final escalate = type == ReconActivityType.caseEscalated;
    final ok = await Get.dialog<bool>(AlertDialog(
      title: Text(escalate ? 'Escalate this case?' : 'End this case?'),
      content: Text(escalate
          ? 'The case ends as Escalated and is passed to your Head. Nothing more '
              'can be logged on it.'
          : 'The case ends as Not completed. Its open invoices stay under '
              'Reconciliation; to continue later, open a new case.'),
      actions: [
        TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel')),
        TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(escalate ? 'Escalate' : 'End case')),
      ],
    ));
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allowed = allowedReconActivityTypes(_eval);
    Iterable<ReconActivityType> of(bool Function(ReconActivityType) test) =>
        allowed.where(test);
    final type = _type;

    // The navigation bar, once, at the outermost edge; Get.bottomSheet's
    // route already lifts the sheet above the keyboard.
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(BSizes.defaultSpace, BSizes.sm,
            BSizes.defaultSpace, BSizes.defaultSpace),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Log a step',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text(widget.view.reconCase.clientName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: BCollectionColors.inkSecondary)),
            const SizedBox(height: BSizes.spaceBtwItems),
            _group('What you did',
                of((t) => t.doneBy == ReconActor.collector && !t.isLifecycle),
                locked: _lockedStageSteps()),
            _group('What the account did',
                of((t) => t.doneBy == ReconActor.account)),
            _group('End the case', of((t) => t.isLifecycle)),
            // The details for the chosen step grow in (and change over) in
            // one motion: the height eases while the old form fades into
            // the new one, instead of the sheet jumping to its new size.
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, if (current != null) current],
                ),
                child: type == null
                    ? const SizedBox.shrink(key: ValueKey('recon-details-none'))
                    : Column(
                        key: ValueKey('recon-details-${type.code}'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _details(context, type),
                      ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _error == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: BSizes.spaceBtwItems),
                      child: Text(_error!,
                          key: const ValueKey('recon-error'),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: BCollectionColors.danger)),
                    ),
            ),
            const SizedBox(height: BSizes.spaceBtwItems),
            ElevatedButton(
              key: const ValueKey('recon-save'),
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48)),
              child: Text(type?.isLifecycle == true
                  ? (type == ReconActivityType.caseEscalated
                      ? 'Escalate case'
                      : 'End case')
                  : 'Log step'),
            ),
          ],
        ),
      ),
    );
  }

  /// The fields for [type]: the question it asks, the invoices it names,
  /// remarks, the next action and photos.
  List<Widget> _details(BuildContext context, ReconActivityType type) {
    final theme = Theme.of(context);
    return [
      const Divider(height: BSizes.spaceBtwSections),
      if (type == ReconActivityType.proofValidated) ...[
        Text('Is the proof valid?', style: theme.textTheme.titleSmall),
        const SizedBox(height: BSizes.xs),
        SegmentedButton<ReconValidationResult>(
          key: const ValueKey('recon-validation'),
          emptySelectionAllowed: true,
          segments: const [
            ButtonSegment(
                value: ReconValidationResult.valid,
                label: Text('Valid'),
                icon: Icon(Iconsax.tick_circle)),
            ButtonSegment(
                value: ReconValidationResult.invalid,
                label: Text('Invalid'),
                icon: Icon(Iconsax.close_circle)),
          ],
          selected: {if (_result != null) _result!},
          onSelectionChanged: (s) =>
              setState(() => _result = s.isEmpty ? null : s.first),
        ),
        const SizedBox(height: BSizes.spaceBtwItems),
      ],
      if (type == ReconActivityType.soaSent) ...[
        TextField(
          key: const ValueKey('recon-soa-amount'),
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
              labelText: 'SOA amount', prefixText: 'PHP '),
        ),
        const SizedBox(height: BSizes.spaceBtwItems),
      ],
      if (_choices.isNotEmpty) ...[
        Text(
            _mustNameInvoices
                ? 'Which invoices does the account say are paid?'
                : 'Invoices (optional; none means all that apply)',
            style: theme.textTheme.titleSmall),
        for (final i in _choices)
          CheckboxListTile(
            key: ValueKey('recon-invoice-${i.invoiceNo}'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: _invoices.contains(i.invoiceNo),
            onChanged: (on) => setState(() => on == true
                ? _invoices.add(i.invoiceNo)
                : _invoices.remove(i.invoiceNo)),
            title: Text(i.invoiceNo),
            subtitle: Text(BFormatter.formatPesoCurrency(i.amount)),
            secondary: ReconChip(
                label: i.status.label,
                color: BReconStyle.invoiceColor(i.status)),
          ),
        const SizedBox(height: BSizes.spaceBtwItems),
      ],
      TextField(
        key: const ValueKey('recon-remarks'),
        controller: _remarks,
        maxLines: 3,
        minLines: 1,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
            labelText: 'Remarks', prefixIcon: Icon(Iconsax.edit)),
      ),
      if (!type.isLifecycle) ...[
        const SizedBox(height: BSizes.spaceBtwInputFields),
        TextField(
          key: const ValueKey('recon-next-action'),
          controller: _nextAction,
          decoration: const InputDecoration(
              labelText: 'Next action (optional)',
              prefixIcon: Icon(Iconsax.arrow_right_3)),
        ),
        const SizedBox(height: BSizes.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const ValueKey('recon-due'),
            onPressed: _pickDue,
            icon: const Icon(Iconsax.calendar_1, size: 18),
            label: Text(_due == null
                ? 'Set a due date'
                : 'Due ${_shown.format(_due!)}'),
          ),
        ),
      ],
      if (_takesPhotos) ...[
        const SizedBox(height: BSizes.xs),
        if (type == ReconActivityType.collectionLetterSent)
          Padding(
            padding: const EdgeInsets.only(bottom: BSizes.xs),
            child: Text('Attach a photo of the letter (required)',
                key: const ValueKey('recon-letter-photo-required'),
                style: theme.textTheme.titleSmall),
          ),
        Wrap(
          spacing: BSizes.sm,
          runSpacing: BSizes.sm,
          children: [
            for (var i = 0; i < _photos.length; i++)
              _Thumb(
                  bytes: _photos[i],
                  onRemove: () => setState(() => _photos.removeAt(i))),
            if (widget.cameraAvailable ?? GetPlatform.isAndroid)
              OutlinedButton.icon(
                key: const ValueKey('recon-camera'),
                onPressed: () => _addPhoto(ImageSource.camera),
                icon: const Icon(Iconsax.camera, size: 18),
                label: const Text('Photo'),
              ),
            OutlinedButton.icon(
              key: const ValueKey('recon-gallery'),
              onPressed: () => _addPhoto(ImageSource.gallery),
              icon: const Icon(Iconsax.gallery, size: 18),
              label: const Text('Gallery'),
            ),
          ],
        ),
      ],
    ];
  }

  /// Stage steps that must wait for an earlier stage, with the reason.
  List<({ReconActivityType type, String reason})> _lockedStageSteps() {
    if (_eval.isClosed) return const [];
    return [
      for (final stage in ReconStage.values)
        if (reconStageLockReason(_eval, stage.type) case final reason?)
          (type: stage.type, reason: reason),
    ];
  }

  Widget _group(String title, Iterable<ReconActivityType> types,
      {List<({ReconActivityType type, String reason})> locked = const []}) {
    if (types.isEmpty && locked.isEmpty) return const SizedBox.shrink();
    final caption = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: BCollectionColors.inkSecondary);
    return Padding(
      padding: const EdgeInsets.only(bottom: BSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: BCollectionColors.inkSecondary)),
          const SizedBox(height: BSizes.xs),
          Wrap(
            spacing: BSizes.sm,
            runSpacing: BSizes.xs,
            children: [
              for (final t in types)
                ChoiceChip(
                  key: ValueKey('recon-type-${t.code}'),
                  avatar: Icon(BReconStyle.activityIcon(t), size: 16),
                  label: Text(t.label),
                  selected: _type == t,
                  onSelected: (_) => _pick(t),
                ),
              for (final l in locked)
                ChoiceChip(
                  key: ValueKey('recon-type-${l.type.code}-locked'),
                  avatar: const Icon(Iconsax.lock, size: 16),
                  label: Text(l.type.label),
                  selected: false,
                  onSelected: null,
                ),
            ],
          ),
          for (final l in locked)
            Padding(
              padding: const EdgeInsets.only(top: BSizes.xs),
              child: Text(l.reason, style: caption),
            ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.bytes, required this.onRemove});

  final Uint8List bytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
            child: Image.memory(bytes,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                    width: 64, height: 64, child: Icon(Iconsax.image))),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: InkWell(
              onTap: onRemove,
              child: const CircleAvatar(
                  radius: 10,
                  backgroundColor: BCollectionColors.ink,
                  child: Icon(Icons.close, size: 12, color: Colors.white)),
            ),
          ),
        ],
      );
}
