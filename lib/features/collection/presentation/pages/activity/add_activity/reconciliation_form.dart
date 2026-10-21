import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/reconciliation_controller.dart';

import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/client_picker_sheet.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/add_activity/widgets/engagement_invoice_picker.dart';

class ReconciliationFormScreen extends StatefulWidget {
  const ReconciliationFormScreen({super.key});

  @override
  State<ReconciliationFormScreen> createState() =>
      _ReconciliationFormScreenState();
}

class _ReconciliationFormScreenState extends State<ReconciliationFormScreen> {
  ClientModel? selectedAccount;
  final List<String> selectedInvoiceIds = [];
  final remarksController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    remarksController.dispose();
    super.dispose();
  }

  bool _saving = false;

  /// What the save is doing now, shown on the overlay so a slow save reads
  /// as work in progress, not as a frozen form.
  String _step = '';

  void _setStep(String step) {
    if (mounted) setState(() => _step = step);
  }

  ReconciliationController? get _tracker =>
      Get.isRegistered<ReconciliationController>()
          ? ReconciliationController.instance
          : null;

  /// The account's open case: an account has at most one, so the form sends
  /// the collector there instead of offering its invoices again.
  ReconCaseView? get _openCase => selectedAccount == null
      ? null
      : _tracker?.openCaseOf(selectedAccount!.id);

  /// The account's invoices a new case may take: none already in an open
  /// case or marked for reconciliation (unless their case has ended).
  List<CollectionItemModel> _openable(CollectionActivityController controller) {
    if (selectedAccount == null) return const [];
    final tracker = _tracker;
    return CollectionActivityController.openableForReconciliation(
      controller.getInvoicesByAccount(selectedAccount!.id),
      inOpenCase: tracker?.openCaseInvoiceIds ?? const {},
      inEndedCase: tracker?.endedCaseInvoiceIds ?? const {},
    );
  }

  /// Opens a Reconciliation Tracker case for the account over the picked
  /// invoices, marks them for reconciliation as before, and goes to the case,
  /// where the next step (usually the SOA) is logged.
  Future<void> _save() async {
    if (_saving || !formKey.currentState!.validate()) return;
    if (selectedAccount == null) {
      BLoaders.errorSnackBar(
          title: 'Error', message: 'Please select an account');
      return;
    }
    final existing = _openCase;
    if (existing != null) {
      BLoaders.errorSnackBar(
          title: 'Case already open',
          message: 'This account is already in case ${existing.caseId}.');
      return;
    }
    if (selectedInvoiceIds.isEmpty) {
      BLoaders.errorSnackBar(
          title: 'Error', message: 'Please select at least one invoice');
      return;
    }

    final controller = CollectionActivityController.instance;
    final account = selectedAccount!;
    final byId = {
      for (final i in controller.getInvoicesByAccount(account.id)) i.id: i
    };

    setState(() {
      _saving = true;
      _step = 'Opening the case';
    });
    try {
      await _openAndMark(controller, account, byId);
    } catch (e) {
      logDebug('ReconciliationFormScreen: open case failed: $e');
      if (mounted) {
        BLoaders.errorSnackBar(
            title: 'Case not opened', message: 'Please try again.');
      }
    } finally {
      // Still here: it failed, so the form is usable again. On success the
      // page has already been replaced by the case.
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openAndMark(
    CollectionActivityController controller,
    ClientModel account,
    Map<String, CollectionItemModel> byId,
  ) async {
    final tracker = ReconciliationController.instance;
    final opened = await tracker.openCase(
      clientCode: account.id,
      clientName: account.name,
      invoices: [
        for (final id in selectedInvoiceIds)
          ReconCaseInvoice(invoiceNo: id, amount: byId[id]?.toBeCollected ?? 0),
      ],
    );
    if (!mounted) return;
    if (opened.isFailure) {
      BLoaders.errorSnackBar(title: 'Case not opened', message: opened.error);
      return;
    }

    final count = selectedInvoiceIds.length;
    _setStep('Marking $count ${count == 1 ? 'invoice' : 'invoices'}');
    await controller.markInvoicesForReconciliation(
      account.id,
      selectedInvoiceIds,
      remarksController.text,
    );
    final remarks = remarksController.text.trim();
    if (remarks.isNotEmpty) {
      _setStep('Saving the remarks');
      await tracker.logActivity(
          caseId: opened.value.caseId,
          type: ReconActivityType.note,
          remarks: remarks);
    }

    // Straight to the case: its next step is the SOA.
    Get.offNamed(BRoutes.reconciliationCase, arguments: opened.value.caseId);
  }

  @override
  Widget build(BuildContext context) {
    final controller = CollectionActivityController.instance;
    final openCase = _openCase;
    final invoices = _openable(controller);
    final canOpen =
        selectedAccount != null && openCase == null && invoices.isNotEmpty;

    // Back is held while the case saves: leaving halfway would leave the
    // case opened but its invoices unmarked.
    return PopScope(
      canPop: !_saving,
      child: Stack(
        children: [
          _form(context, controller, openCase, invoices, canOpen),
          OpeningCaseOverlay(
            visible: _saving,
            step: _step,
            invoiceCount: selectedInvoiceIds.length,
          ),
        ],
      ),
    );
  }

  Widget _form(
    BuildContext context,
    CollectionActivityController controller,
    ReconCaseView? openCase,
    List<CollectionItemModel> invoices,
    bool canOpen,
  ) {
    return Scaffold(
      appBar: const BAppBar(
          title: Text('Open Reconciliation Case'), showBackArrow: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            BSizes.defaultSpace,
            BSizes.defaultSpace,
            BSizes.defaultSpace,
            BSizes.defaultSpace + MediaQuery.paddingOf(context).bottom,
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account: an existing client, searched in the registry.
                ClientPickerField(
                  key: const ValueKey('reconciliation-account'),
                  value: selectedAccount,
                  search: controller.searchClientRegistry,
                  searchKnown: controller.searchKnownAccounts,
                  onChanged: (client) => setState(() {
                    selectedAccount = client;
                    selectedInvoiceIds.clear();
                  }),
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),
                // The checklist unfolds under the account rather than
                // popping in, so the form grows instead of jumping.
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: selectedAccount == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(
                              bottom: BSizes.spaceBtwInputFields),
                          child: openCase != null
                              ? _AlreadyOpenNotice(
                                  caseId: openCase.caseId,
                                  onOpen: () => Get.offNamed(
                                      BRoutes.reconciliationCase,
                                      arguments: openCase.caseId),
                                )
                              : invoices.isEmpty
                                  ? const _NothingToReconcile()
                                  : EngagementInvoicePicker(
                                      invoices: invoices,
                                      selectedIds: selectedInvoiceIds,
                                      onToggle: (id, selected) => setState(() {
                                        selected
                                            ? selectedInvoiceIds.add(id)
                                            : selectedInvoiceIds.remove(id);
                                      }),
                                      onToggleAll: (all) => setState(() {
                                        selectedInvoiceIds.clear();
                                        if (all) {
                                          selectedInvoiceIds.addAll(
                                              invoices.map((inv) => inv.id));
                                        }
                                      }),
                                    ),
                        ),
                ),
                TextFormField(
                  controller: remarksController,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Remarks (optional)',
                    prefixIcon: Icon(Iconsax.edit),
                  ),
                ),
                const SizedBox(height: BSizes.spaceBtwSections),
                ElevatedButton(
                  onPressed: _saving || !canOpen ? null : _save,
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48)),
                  child: const Text('Open reconciliation case'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The picked account is already in an open case: its invoices are worked
/// there, and a second case would be refused on save.
class _AlreadyOpenNotice extends StatelessWidget {
  const _AlreadyOpenNotice({required this.caseId, required this.onOpen});

  final String caseId;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BSizes.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Already under reconciliation',
              style: theme.textTheme.titleSmall),
          const SizedBox(height: BSizes.xs),
          Text(
            'This account has an open case ($caseId). Log its next step '
            'there; a new case can be opened once it ends.',
            style: theme.textTheme.bodySmall,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onOpen,
              child: const Text('Go to the case'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Every open invoice of the account is already in a case, or marked.
class _NothingToReconcile extends StatelessWidget {
  const _NothingToReconcile();

  @override
  Widget build(BuildContext context) {
    return Text(
      'No invoices left to reconcile for this account.',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

/// Covers the form while the case is opened, its invoices are marked and the
/// remarks are saved: a few seconds with nothing on screen read as a frozen
/// form, or as a tap that did not take. Absorbs taps, so a second tap cannot
/// open a second case.
class OpeningCaseOverlay extends StatelessWidget {
  const OpeningCaseOverlay({
    super.key,
    required this.visible,
    required this.step,
    required this.invoiceCount,
  });

  final bool visible;
  final String step;
  final int invoiceCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: !visible
              ? const SizedBox.shrink(key: ValueKey('open-case-idle'))
              : Material(
                  key: const ValueKey('open-case-busy'),
                  color: BCollectionColors.ink.withValues(alpha: 0.45),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(BSizes.defaultSpace),
                      padding: const EdgeInsets.symmetric(
                          horizontal: BSizes.lg, vertical: BSizes.defaultSpace),
                      decoration: BoxDecoration(
                        color: BCollectionColors.surface,
                        borderRadius:
                            BorderRadius.circular(BSizes.borderRadiusLg),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                          const SizedBox(height: BSizes.md),
                          Text(
                            'Opening reconciliation case',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: BSizes.xs),
                          Text(
                            step,
                            key: const ValueKey('open-case-step'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: BSizes.xs),
                          Text(
                            '$invoiceCount '
                            '${invoiceCount == 1 ? 'invoice' : 'invoices'} · '
                            'please wait',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: BCollectionColors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
