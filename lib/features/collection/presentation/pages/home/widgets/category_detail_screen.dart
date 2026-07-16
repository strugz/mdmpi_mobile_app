import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/widgets/account_item_card.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/widgets/invoice_item_card.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/due_date_helper.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:get/get.dart';
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
                padding: const EdgeInsets.all(BSizes.defaultSpace),
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
          Expanded(
            child: Obx(() {
              List<ClientModel> accounts = [];

              switch (title) {
                case 'Settled':
                  accounts = controller.settledAccounts;
                  break;
                case 'Due Date':
                  accounts = controller.overdueAccounts;
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
                  final invoices = title == 'Settled' 
                      ? controller.getSettledInvoicesByAccount(client.id)
                      : controller.getOverdueInvoicesByAccount(client.id);

                  return AccountItemCard(
                    client: client,
                    invoiceCount: invoices.length,
                    totalAmount: invoices.fold(0, (sum, i) => sum + i.toBeCollected),
                    totalCollected: invoices.fold(0, (sum, i) => sum + i.totalCollected),
                    onTap: () => _showAccountInvoices(context, client, invoices),
                    onInfoTap: () {},
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
