import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/data/models/directory_user.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/controllers/signup_controller.dart';

/// Sign-up fields only Collection has: the Head, saved as `HeadKey` /
/// `HeadName` like Settings → My Head saves it.
///
/// Optional. Before the first login the directory is often empty (masters
/// are not downloaded yet), so the user can set the Head later in Settings.
class CollectionSignupFields extends StatelessWidget {
  const CollectionSignupFields({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SignupController>();
    return Obx(() {
      final hasHead = controller.headKey.value.isNotEmpty;
      final text = hasHead
          ? '${controller.headName.value} (${controller.headKey.value})'
          : '';
      return TextFormField(
        // Keyed by the text so a new choice rebuilds the read-only field.
        key: ValueKey('signup-head-$text'),
        readOnly: true,
        initialValue: text,
        onTap: () => _openPicker(context, controller),
        decoration: InputDecoration(
          labelText: 'My Head (optional)',
          prefixIcon: const Icon(Iconsax.user_tick),
          suffixIcon: hasHead
              ? IconButton(
                  tooltip: 'Clear',
                  onPressed: controller.clearHead,
                  icon: const Icon(Icons.close))
              : null,
        ),
      );
    });
  }

  static void _openPicker(BuildContext context, SignupController controller) {
    controller.headQuery.value = '';
    controller.loadHeadDirectory();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.6,
            child: Padding(
              padding: const EdgeInsets.all(BSizes.defaultSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Choose your Head',
                      style: Theme.of(sheetContext).textTheme.titleMedium),
                  const SizedBox(height: BSizes.spaceBtwItems),
                  TextField(
                    key: const ValueKey('signup-head-search'),
                    onChanged: (v) => controller.headQuery.value = v,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Iconsax.search_normal),
                      hintText: 'Search by name, code or department',
                    ),
                  ),
                  const SizedBox(height: BSizes.sm),
                  Expanded(
                    child: Obx(() {
                      if (controller.headDirectoryLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final rows = controller.filteredHeadDirectory;
                      if (rows.isEmpty) {
                        return Center(
                          child: Text(
                            controller.headDirectory.isEmpty
                                ? 'The directory is not available yet.\n'
                                    'You can set your Head later in '
                                    'Settings > My Head.'
                                : 'No one matches your search.',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final u = rows[i];
                          final selected = u.key == controller.headKey.value;
                          return ListTile(
                            key: ValueKey('signup-head-person-${u.key}'),
                            leading: CircleAvatar(
                              child: Text(u.key.length > 3
                                  ? u.key.substring(0, 3)
                                  : u.key),
                            ),
                            title: Text(u.name),
                            subtitle: Text(_meta(u)),
                            selected: selected,
                            trailing: selected
                                ? const Icon(Iconsax.tick_circle)
                                : null,
                            onTap: () {
                              controller.selectHead(u);
                              Navigator.of(sheetContext).pop();
                            },
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _meta(DirectoryUser u) =>
      [u.key, if (u.department.isNotEmpty) u.department].join(' · ');
}
