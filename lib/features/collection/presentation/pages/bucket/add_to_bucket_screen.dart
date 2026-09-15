import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';

/// Supervisor "Add to Bucket": create a collection invoice, saved to the server
/// (DB first) and added to the shared bucket.
class AddToBucketScreen extends StatefulWidget {
  const AddToBucketScreen({super.key});

  @override
  State<AddToBucketScreen> createState() => _AddToBucketScreenState();
}

class _AddToBucketScreenState extends State<AddToBucketScreen> {
  final _formKey = GlobalKey<FormState>();

  final _clientName = TextEditingController();
  final _clientCode = TextEditingController();
  final _clientAddress = TextEditingController();
  final _clientContact = TextEditingController();
  final _documentRefs = TextEditingController();
  final _amount = TextEditingController();
  final _bankName = TextEditingController();
  final _dueDate = TextEditingController();
  final _remarks = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _clientName.dispose();
    _clientCode.dispose();
    _clientAddress.dispose();
    _clientContact.dispose();
    _documentRefs.dispose();
    _amount.dispose();
    _bankName.dispose();
    _dueDate.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final code = _clientCode.text.trim();
    final name = _clientName.text.trim();
    final clientId = code.isNotEmpty ? code : name;
    final refs = _documentRefs.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final ok = await Get.find<CollectionActivityController>().addInvoiceToBucket(
      clientId: clientId,
      clientName: name,
      clientCode: code,
      clientAddress: _clientAddress.text.trim(),
      clientContact: _clientContact.text.trim(),
      documentReferences: refs,
      toBeCollected: double.tryParse(_amount.text.trim()) ?? 0,
      bankName: _bankName.text.trim().isEmpty ? null : _bankName.text.trim(),
      remarks: _remarks.text.trim().isEmpty ? null : _remarks.text.trim(),
      dueDate: _dueDate.text.trim().isEmpty ? null : _dueDate.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Get.back();
      BLoaders.successSnackBar(
          title: 'Added', message: 'Invoice added to the collection bucket.');
    }
    // Failure feedback is surfaced by the repository.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add to Bucket')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(BSizes.defaultSpace),
          children: [
            _field(_clientName, 'Client Name *', required: true),
            _field(_clientCode, 'Client Code / ID'),
            _field(_clientAddress, 'Client Address'),
            _field(_clientContact, 'Contact Number',
                keyboard: TextInputType.phone),
            _field(_documentRefs, 'Invoice / Document References (comma-separated)'),
            _field(
              _amount,
              'Amount Due *',
              required: true,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              formatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            _field(_bankName, 'Bank Name'),
            _field(_dueDate, 'Due Date (e.g. 2026-09-30)'),
            _field(_remarks, 'Remarks', maxLines: 3),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(BSizes.defaultSpace),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add to Bucket'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboard,
    int maxLines = 1,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BSizes.spaceBtwInputFields),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        inputFormatters: formatters,
        decoration: InputDecoration(labelText: label),
        validator: validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
                : null),
      ),
    );
  }
}
