import 'package:mdmpi_mobile_app/data/services/collection_sms_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/bank_field.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/b_amount_blur_pad.dart';

/// For Deposit: the collector's activity, nothing more.
///
/// It asked for an account and for invoices from the Collection Bucket, as if
/// a deposit settled them. It does not: a deposit counts toward neither
/// Actual Collection nor Collected this Month (revisions list item 9), and is
/// not tied to an account. So the form is what the deposit slip says — bank,
/// amount, check number — and optional remarks.
class DepositFormScreen extends StatefulWidget {
  const DepositFormScreen({super.key});

  @override
  State<DepositFormScreen> createState() => _DepositFormScreenState();
}

class _DepositFormScreenState extends State<DepositFormScreen> {
  final bankNameController = TextEditingController();
  final amountController = TextEditingController();
  final checkNumberController = TextEditingController();
  final remarksController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    bankNameController.dispose();
    amountController.dispose();
    checkNumberController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;

    CollectionActivityController.instance.saveGlobalActivity(
      type: 'Deposit',
      // No account: the deposit is not recorded against one.
      clientId: '',
      accountName: '',
      remarks: remarksController.text.trim(),
      totalCollected: BFormatter.parseAmount(amountController.text),
      bankName: bankNameController.text.trim(),
      checkNumber: checkNumberController.text.trim(),
    );

    Get.back();
    if (CollectionSmsService.smsFollows()) return;
    BLoaders.successSnackBar(
        title: 'Deposit recorded',
        message: 'Saved as your activity. It does not count toward Actual '
            'Collection or Collected this Month.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BAppBar(title: Text('Record Deposit'), showBackArrow: true),
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
                BBankField(
                  controller: bankNameController,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Bank is required'
                      : null,
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),

                BAmountBlurPad(
                  controller: amountController,
                  child: TextFormField(
                    key: const ValueKey('deposit-amount'),
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      hintText: '0.00',
                      prefixIcon: Icon(Iconsax.money),
                      prefixText: '₱ ',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Amount is required';
                      }
                      if (BFormatter.parseAmount(value) <= 0) {
                        return 'Enter an amount greater than zero';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),

                TextFormField(
                  key: const ValueKey('deposit-check-number'),
                  controller: checkNumberController,
                  keyboardType: BCheckNumberInput.keyboardType,
                  inputFormatters: BCheckNumberInput.formatters,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Check Number',
                    prefixIcon: Icon(Iconsax.card_edit),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Check number is required'
                      : null,
                ),
                const SizedBox(height: BSizes.spaceBtwInputFields),

                TextFormField(
                  key: const ValueKey('deposit-remarks'),
                  controller: remarksController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Remarks (optional)',
                    prefixIcon: Icon(Iconsax.edit),
                  ),
                ),
                const SizedBox(height: BSizes.spaceBtwSections),

                ElevatedButton(
                  key: const ValueKey('deposit-save'),
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48)),
                  child: const Text('Record deposit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
