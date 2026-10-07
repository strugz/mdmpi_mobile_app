import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/data/models/directory_user.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/my_head_controller.dart';

/// Settings → *My Head* (Collection TODO item 13).
///
/// The chosen Head on top with a Clear action, a suggestion from the CNTMST
/// hierarchy while nothing is chosen, then a searchable list of everyone in
/// the user directory. Tapping a person makes them the Head after a
/// confirmation.
class MyHeadScreen extends StatelessWidget {
  const MyHeadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyHeadController());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const BAppBar(title: Text('My Head'), showBackArrow: true),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(BSizes.defaultSpace,
                  BSizes.defaultSpace, BSizes.defaultSpace, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CurrentHeadCard(controller: controller),
                  Obx(() {
                    final s = controller.suggestion.value;
                    if (s == null || controller.hasHead) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: BSizes.sm),
                      child: _SuggestionTile(
                          person: s,
                          onUse: () => _confirmChoose(context, controller, s)),
                    );
                  }),
                  const SizedBox(height: BSizes.spaceBtwItems),
                  TextField(
                    key: const ValueKey('my-head-search'),
                    onChanged: controller.search,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Iconsax.search_normal),
                      hintText: 'Search by name, code or department',
                    ),
                  ),
                  const SizedBox(height: BSizes.sm),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final err = controller.error.value;
                if (err != null && controller.people.isEmpty) {
                  return _Message(
                    icon: Iconsax.warning_2,
                    title: 'Directory unavailable',
                    body: err,
                    action: TextButton(
                        onPressed: () => controller.load(refresh: true),
                        child: const Text('Try again')),
                  );
                }
                // Read the query so the list rebuilds as it changes.
                final _ = controller.query.value;
                final rows = controller.filtered;
                if (rows.isEmpty) {
                  return const _Message(
                    icon: Iconsax.user_search,
                    title: 'No one matches',
                    body: 'Try a name, a code such as JCA, or a department.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(BSizes.defaultSpace, 0,
                      BSizes.defaultSpace, BSizes.defaultSpace),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final u = rows[i];
                    final isHead = controller.isHead(u);
                    return ListTile(
                      key: ValueKey('my-head-person-${u.key}'),
                      leading: CircleAvatar(
                        child: Text(u.key.length > 3
                            ? u.key.substring(0, 3)
                            : u.key),
                      ),
                      title: Text(u.name),
                      subtitle: Text(_meta(u)),
                      trailing: isHead
                          ? Icon(Iconsax.tick_circle,
                              color: theme.colorScheme.primary)
                          : null,
                      selected: isHead,
                      onTap: isHead
                          ? null
                          : () => _confirmChoose(context, controller, u),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  static String _meta(DirectoryUser u) {
    final parts = [u.key, if (u.department.isNotEmpty) u.department];
    return parts.join(' · ');
  }

  static Future<void> _confirmChoose(BuildContext context,
      MyHeadController controller, DirectoryUser person) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set as your Head?'),
        content: Text('${person.name} (${person.key}) will receive your '
            'Done Engagement notices.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              key: const ValueKey('my-head-confirm'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Set as Head')),
        ],
      ),
    );
    if (ok != true) return;
    final message = await controller.choose(person);
    if (message == null) {
      BLoaders.successSnackBar(
          title: 'Head set', message: '${person.name} is now your Head.');
    } else {
      BLoaders.errorSnackBar(title: 'Not saved', message: message);
    }
  }
}

class _CurrentHeadCard extends StatelessWidget {
  const _CurrentHeadCard({required this.controller});

  final MyHeadController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // One Obx for the card: it reads the saved key/name, the directory entry
    // and the saving flag, all of which change on save/clear.
    return Obx(() => _card(theme));
  }

  Widget _card(ThemeData theme) {
    final has = controller.hasHead;
    final name = controller.headDisplayName;
    final key = controller.savedHeadKey.value;
    final person = controller.head.value;
    final saving = controller.isSaving.value;

    return Card(
      key: const ValueKey('my-head-current'),
      child: Padding(
        padding: const EdgeInsets.all(BSizes.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              child: Icon(has ? Iconsax.user_tick : Iconsax.user),
            ),
            const SizedBox(width: BSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Head', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 2),
                  Text(
                    has ? (name.isEmpty ? key : name) : 'Not set',
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (has)
                    Text(
                      person == null
                          ? '$key · not in the directory any more'
                          : MyHeadScreen._meta(person),
                      style: theme.textTheme.bodySmall,
                    )
                  else
                    Text('Pick the person who receives your Done Engagement '
                        'notices.',
                        style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (has)
              TextButton(
                key: const ValueKey('my-head-clear'),
                onPressed: saving
                    ? null
                    : () async {
                        final message = await controller.clear();
                        if (message == null) {
                          BLoaders.successSnackBar(
                              title: 'Head cleared',
                              message: 'No Head is set.');
                        } else {
                          BLoaders.errorSnackBar(
                              title: 'Not saved', message: message);
                        }
                      },
                child: const Text('Clear'),
              ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.person, required this.onUse});

  final DirectoryUser person;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: const ValueKey('my-head-suggestion'),
      color: theme.colorScheme.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
      child: ListTile(
        leading: const Icon(Iconsax.lamp_on),
        title: Text('Suggested: ${person.name}'),
        subtitle: Text('${MyHeadScreen._meta(person)} · from the '
            'CNTMST hierarchy, not set until you confirm'),
        trailing: TextButton(
            key: const ValueKey('my-head-use-suggestion'),
            onPressed: onUse,
            child: const Text('Use')),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(
      {required this.icon, required this.title, required this.body, this.action});

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BSizes.defaultSpace),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.outline),
            const SizedBox(height: BSizes.sm),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(body,
                textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
            if (action != null) action!,
          ],
        ),
      ),
    );
  }
}
