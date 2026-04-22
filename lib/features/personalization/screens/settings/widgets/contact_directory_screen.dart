import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/data/models/cnstmst_model.dart';
import 'package:mdmpi_mobile_app/data/models/contact_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/contact_directory_controller.dart';

class ContactDirectoryScreen extends StatefulWidget {
  const ContactDirectoryScreen({super.key});

  @override
  State<ContactDirectoryScreen> createState() => _ContactDirectoryScreenState();
}

class _ContactDirectoryScreenState extends State<ContactDirectoryScreen> {
  final ContactDirectoryController controller =
      Get.find<ContactDirectoryController>();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _initialController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();

  @override
  void dispose() {
    _initialController.dispose();
    _departmentController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  Future<void> _showAddContactDialog(BuildContext context) async {
    _initialController.clear();
    _departmentController.clear();
    _contactNumberController.clear();
    CNTMSTModel? selectedDirectoryContact;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext dialogContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            BSizes.defaultSpace,
            BSizes.defaultSpace,
            BSizes.defaultSpace,
            MediaQuery.of(dialogContext).viewInsets.bottom +
                BSizes.defaultSpace,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Contact',
                        style: Theme.of(dialogContext).textTheme.titleLarge,
                      ),
                      const SizedBox(height: BSizes.spaceBtwItems),
                      Obx(
                        () => DropdownButtonFormField<CNTMSTModel>(
                          value: selectedDirectoryContact,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Select Contact from Directory',
                          ),
                          hint: const Text('Choose a contact'),
                          items: controller.directoryOptions
                              .map(
                                (item) => DropdownMenuItem<CNTMSTModel>(
                                  value: item,
                                  child: Text(
                                    '${item.cntmnn ?? '-'} - ${item.cntdpt ?? '-'}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setModalState(() {
                              selectedDirectoryContact = value;
                            });

                            if (value != null) {
                              _initialController.text = value.cntmnn ?? '';
                              _departmentController.text = value.cntdpt ?? '';
                              _contactNumberController.text = value.cntnum ?? '';
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: BSizes.spaceBtwInputFields),
                      TextFormField(
                        controller: _initialController,
                        decoration: const InputDecoration(labelText: 'Initial'),
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: BSizes.spaceBtwInputFields),
                      TextFormField(
                        controller: _departmentController,
                        decoration:
                            const InputDecoration(labelText: 'Department'),
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: BSizes.spaceBtwInputFields),
                      TextFormField(
                        controller: _contactNumberController,
                        keyboardType: TextInputType.phone,
                        decoration:
                            const InputDecoration(labelText: 'Contact Number'),
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: BSizes.spaceBtwItems),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                            await controller.addContact(
                              initial: _initialController.text,
                              department: _departmentController.text,
                              contactNumber: _contactNumberController.text,
                            );

                            if (!dialogContext.mounted) {
                              return;
                            }

                            Navigator.of(dialogContext).pop();
                            BLoaders.successSnackBar(
                              title: 'Saved',
                              message: 'Contact added successfully',
                            );
                          },
                          child: const Text('Save Contact'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteContact(
    BuildContext context,
    ContactModel contact,
  ) async {
    if (contact.id == null) {
      BLoaders.errorSnackBar(
        title: 'Delete Failed',
        message: 'This contact cannot be deleted because it has no local id.',
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Contact'),
          content: Text(
            'Are you sure you want to delete ${contact.initial}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await controller.deleteContact(contact);
    BLoaders.successSnackBar(
      title: 'Deleted',
      message: 'Contact removed successfully',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BAppBar(
        title: Text(
          'Contact Directory',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        showBackArrow: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddContactDialog(context),
        child: const Icon(Iconsax.add),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.contacts.isEmpty) {
          return const Center(
            child: Text('No contacts yet. Tap + to add one.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(BSizes.defaultSpace),
          itemCount: controller.contacts.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: BSizes.spaceBtwItems),
          itemBuilder: (context, index) {
            final contact = controller.contacts[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    contact.initial.isNotEmpty
                        ? contact.initial.substring(0, 1).toUpperCase()
                        : '-',
                  ),
                ),
                title: Text(contact.initial),
                subtitle: Text(
                  '${contact.department}\n${contact.contactNumber}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Iconsax.trash),
                  onPressed: () => _deleteContact(context, contact),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
