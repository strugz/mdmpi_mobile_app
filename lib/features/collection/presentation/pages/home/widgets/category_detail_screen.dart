import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/area_selection/widgets/filter_by_area_button.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/widgets/account_item_card.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/widgets/invoice_item_card.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';

class CategoryDetailScreen extends StatelessWidget {
  const CategoryDetailScreen({
    super.key,
    required this.title,
    required this.color,
  });

  final String title;
  final Color color;

  void _showAccountInvoices(BuildContext context, ClientModel client, List<CollectionItemModel> invoices) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(BSizes.borderRadiusLg)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(BSizes.md),
              child: Text(
                'Invoices for ${client.name}',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                // Last card clears the system navigation bar.
                padding: EdgeInsets.fromLTRB(
                    BSizes.defaultSpace,
                    BSizes.defaultSpace,
                    BSizes.defaultSpace,
                    BSizes.defaultSpace + MediaQuery.paddingOf(context).bottom),
                itemCount: invoices.length,
                separatorBuilder: (_, __) => const SizedBox(height: BSizes.spaceBtwItems),
                itemBuilder: (context, index) {
                  return InvoiceItemCard(
                    item: invoices[index],
                    isSelected: false,
                    onTap: () {},
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = CollectionActivityController.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: BSizes.spaceBtwItems),
          const BFilterByAreaButton(),
          const SizedBox(height: BSizes.spaceBtwItems),
          Expanded(
            child: Obx(() {
              if (title == 'Advanced Payment') {
                final unassigned = controller.filteredUnassignedAdvancedPayments;
                final resolvedAccounts = controller.advancedPaymentAccounts;

                if (unassigned.isEmpty && resolvedAccounts.isEmpty) {
                  return const Center(child: Text('No advanced payments found.'));
                }

                return ListView(
                  padding: const EdgeInsets.all(BSizes.defaultSpace),
                  children: [
                    if (unassigned.isNotEmpty) ...[
                      Text('Unassigned Payments', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: BSizes.sm),
                      ...unassigned.map((pay) {
                        final client = controller.masterAccountList.firstWhere((c) => c.id == pay['clientId'], orElse: () => ClientModel.empty());
                                              return GestureDetector(
                                                onTap: () => _showPaymentDetailSheet(context, controller, pay),
                                                child: Container(
                                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                                  padding: const EdgeInsets.all(BSizes.md),
                                                  decoration: BoxDecoration(
                                                    color: BColors.white,
                                                    borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
                                                    border: Border.all(color: BColors.grey),
                                                    boxShadow: [BoxShadow(color: BColors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(client.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                            const SizedBox(height: BSizes.xs),
                                                            Text('Date: ${pay['date']}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: BColors.darkGrey)),
                                                          ],
                                                        ),
                                                      ),
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.end,
                                                        children: [
                                                          Text(BFormatter.formatPesoCurrency(pay['amount']), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: BColors.primary, fontWeight: FontWeight.bold)),
                                                          const SizedBox(height: BSizes.xs),
                                                          SizedBox(
                                                            height: 32,
                                                            child: ElevatedButton(
                                                              onPressed: () => _showPaymentDetailSheet(context, controller, pay),
                                                              child: const Text('Assign'),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }),
                      const SizedBox(height: BSizes.spaceBtwSections),
                    ],
                  ],
                );
              }

              List<ClientModel> accounts = [];

              switch (title) {
                case 'Settled':
                  accounts = controller.settledAccounts;
                  break;
                case 'Due Date':
                  accounts = controller.overdueAccounts;
                  break;
                case 'Reconciliation':
                  accounts = controller.reconciliationAccounts;
                  break;
                default:
                  accounts = [];
              }

              if (accounts.isEmpty) {
                return const Center(
                  child: Text('No accounts found for this category.'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(BSizes.defaultSpace),
                itemCount: accounts.length,
                separatorBuilder: (_, __) => const SizedBox(height: BSizes.spaceBtwItems),
                itemBuilder: (context, index) {
                  final client = accounts[index];
                  List<CollectionItemModel> invoices = [];
                  switch (title) {
                    case 'Settled':
                      invoices = controller.getSettledInvoicesByAccount(client.id);
                      break;
                    case 'Due Date':
                      invoices = controller.getOverdueInvoicesByAccount(client.id);
                      break;
                    case 'Reconciliation':
                      invoices = controller.getReconciliationInvoicesByAccount(client.id);
                      break;
                  }

                  return AccountItemCard(
                    client: client,
                    invoiceCount: invoices.length,
                    totalAmount: invoices.fold(0.0, (sum, i) => sum + i.toBeCollected),
                    totalCollected: invoices.fold(0.0, (sum, i) => sum + i.totalCollected),
                    onTap: () => _showAccountInvoices(context, client, invoices),
                    onInfoTap: () {},
                    onClaimTap: title == 'Reconciliation' ? () => controller.claimAccount(client.id) : null,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetailSheet(BuildContext context, CollectionActivityController controller, Map<String, dynamic> payment) {
    final invoiceNumberController = TextEditingController();
    final amountDueController = TextEditingController(text: payment['amount']?.toString() ?? '');
    final dueDateController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      SingleChildScrollView(
        child: Padding(
          // Keyboard + navigation bar, each counted once (the sheet has fields).
          padding: EdgeInsets.fromLTRB(
              BSizes.defaultSpace,
              BSizes.defaultSpace,
              BSizes.defaultSpace,
              BSizes.defaultSpace +
                  MediaQuery.viewInsetsOf(context).bottom +
                  MediaQuery.paddingOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Text('Payment Details', style: Theme.of(context).textTheme.headlineSmall)),
              const SizedBox(height: BSizes.md),
              Text('Amount: ${BFormatter.formatPesoCurrency(payment['amount'] ?? 0)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: BSizes.xs),
              Text('Date: ${payment['date'] ?? ''}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: BColors.darkGrey)),
              const SizedBox(height: BSizes.spaceBtwInputFields),
              Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: invoiceNumberController,
                    decoration: const InputDecoration(labelText: 'Invoice Number'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: BSizes.spaceBtwInputFields),
                  TextFormField(
                    controller: amountDueController,
                    decoration: const InputDecoration(labelText: 'Amount Due'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: BSizes.spaceBtwInputFields),
                  TextFormField(
                    controller: dueDateController,
                    decoration: const InputDecoration(
                      labelText: 'Due Date',
                      hintText: 'YYYY-MM-DD',
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        dueDateController.text = DateFormat('yyyy-MM-dd').format(date);
                      }
                    },
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ],
              ),
              ),
              const SizedBox(height: BSizes.spaceBtwSections),
              Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                const SizedBox(width: BSizes.sm),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      controller.assignInvoiceToPayment(
                        paymentId: payment['id'],
                        invoiceNumber: invoiceNumberController.text,
                        amountDue: double.tryParse(amountDueController.text.replaceAll(',', '')) ?? 0,
                        dueDate: dueDateController.text,
                      );
                      Get.back();
                      BLoaders.successSnackBar(title: 'Assigned', message: 'Invoice assigned to payment.');
                    }
                  },
                  child: const Text('Assign'),
                ),
              ],
              ),
              const SizedBox(height: BSizes.md),
            ],
          ),
        ),
      ),
      backgroundColor: BColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(BSizes.borderRadiusLg)),
      ),
    );
  }
}
