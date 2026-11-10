import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/unfinished_requests_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/unfinished/unfinished_request.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/unfinished/unfinished_request_opener.dart';

/// Every request this user should see through that has not reached a final
/// status, grouped by type, oldest first. Opened from the 08:00 reminder or
/// Settings; a row opens the request as its own list would.
class UnfinishedRequestsScreen extends StatefulWidget {
  const UnfinishedRequestsScreen({super.key, this.onOpen});

  /// Opens a row; defaults to [BUnfinishedRequestOpener.open].
  final void Function(BuildContext context, UnfinishedRequest request)? onOpen;

  @override
  State<UnfinishedRequestsScreen> createState() =>
      _UnfinishedRequestsScreenState();
}

class _UnfinishedRequestsScreenState extends State<UnfinishedRequestsScreen> {
  final controller = Get.find<UnfinishedRequestsController>();

  @override
  void initState() {
    super.initState();
    // The reminder may be from an earlier day: show what is true now.
    controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BAppBar(
          title: Text('Unfinished requests'), showBackArrow: true),
      body: RefreshIndicator(
        onRefresh: controller.reload,
        child: Obx(() {
          final summary = controller.summary.value;
          if (summary.total == 0) {
            return controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : const _AllFinished();
          }
          return ListView(
            padding: const EdgeInsets.all(BSizes.defaultSpace),
            children: [
              Text(
                '${summary.title}. These haven\'t reached their final '
                'status yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              for (final entry in summary.byType.entries) ...[
                const SizedBox(height: BSizes.spaceBtwSections),
                Text(
                  '${UnfinishedSummary.labelFor(entry.key)} (${entry.value})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: BSizes.sm),
                for (final request
                    in summary.requests.where((r) => r.type == entry.key))
                  _UnfinishedTile(
                    request: request,
                    onTap: () => (widget.onOpen ?? BUnfinishedRequestOpener.open)
                        (context, request),
                  ),
              ],
              // Clears the system navigation bar (Android edge-to-edge).
              const SafeArea(top: false, child: SizedBox.shrink()),
            ],
          );
        }),
      ),
    );
  }
}

class _UnfinishedTile extends StatelessWidget {
  const _UnfinishedTile({required this.request, required this.onTap});

  final UnfinishedRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final created = _created(request.createdAt);
    return Card(
      margin: const EdgeInsets.only(bottom: BSizes.sm),
      child: ListTile(
        key: ValueKey('unfinished-${request.type.name}-${request.id}'),
        onTap: onTap,
        title: Text(
          request.client.trim().isEmpty
              ? 'Request #${request.id}'
              : '#${request.id} · ${request.client}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          created == null ? request.status : '${request.status} · $created',
          style: TextStyle(color: scheme.primary),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  static String? _created(String raw) {
    final at = DateTime.tryParse(raw.trim());
    return at == null ? null : 'Created ${DateFormat('MMM d, yyyy').format(at)}';
  }
}

class _AllFinished extends StatelessWidget {
  const _AllFinished();

  @override
  Widget build(BuildContext context) {
    // A ListView so pull-to-refresh still works when empty.
    return ListView(
      padding: const EdgeInsets.all(BSizes.defaultSpace),
      children: [
        const SizedBox(height: 120),
        Icon(Icons.task_alt,
            size: 64, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: BSizes.spaceBtwItems),
        Text(
          'All your requests are finished',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
