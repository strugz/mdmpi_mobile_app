import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_sms_outbox_dao.dart';
import 'package:mdmpi_mobile_app/data/services/collection_sms_service.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_sms_outbox_controller.dart';

/// Settings → SMS Outbox. Every Collection SMS goes out from here in the
/// background, one by one. What is not sent yet comes first (sending, being
/// retried, failed, not confirmed), with Send now and Discard; then what was
/// sent today. Sent messages are cleared at midnight. Each message shows
/// every recipient and how its send ended.
class CollectionSmsOutboxScreen extends StatelessWidget {
  const CollectionSmsOutboxScreen({super.key});

  static final DateFormat _when = DateFormat('MMM d, h:mm a');

  static String when(String iso) {
    final t = DateTime.tryParse(iso);
    return t == null ? iso : _when.format(t);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CollectionSmsOutboxController>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('SMS Outbox')),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: Obx(() {
          final attention = controller.needsAttention;
          final delivered = controller.delivered;
          final busy =
              controller.resendingAll.value || controller.resending.value != null;
          if (controller.messages.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 120),
                Icon(Iconsax.sms, size: 40, color: BCollectionColors.inkMuted),
                const SizedBox(height: BSizes.sm),
                Center(
                  child: Text(
                    controller.isLoading.value
                        ? 'Loading...'
                        : 'No Collection SMS yet.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: BCollectionColors.inkSecondary),
                  ),
                ),
              ],
            );
          }
          return ListView(
            padding: EdgeInsets.fromLTRB(
                BSizes.defaultSpace,
                BSizes.defaultSpace,
                BSizes.defaultSpace,
                BSizes.defaultSpace + MediaQuery.paddingOf(context).bottom),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Not sent yet (${attention.length})',
                        key: const ValueKey('sms-outbox-attention'),
                        style: theme.textTheme.titleMedium),
                  ),
                  if (controller.resendable.length > 1)
                    TextButton.icon(
                      key: const ValueKey('sms-outbox-resend-all'),
                      onPressed: busy ? null : controller.resendAll,
                      icon: const Icon(Iconsax.refresh, size: 18),
                      label: const Text('Send all now'),
                    ),
                ],
              ),
              const SizedBox(height: BSizes.sm),
              if (attention.isEmpty)
                Text('Every SMS went out.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: BCollectionColors.inkSecondary))
              else
                for (final m in attention)
                  _MessageCard(message: m, controller: controller, busy: busy),
              const SizedBox(height: BSizes.spaceBtwSections),
              Text('Sent today (${delivered.length})',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: BSizes.sm),
              for (final m in delivered)
                _MessageCard(message: m, controller: controller, busy: busy),
            ],
          );
        }),
      ),
    );
  }
}

/// How a message stands, in the collector's words, and its colour. A
/// failure the app is still trying again by itself reads "Retrying".
(String, Color) _statusLabel(SmsOutboxRecord m) {
  final retrying = m.retryableNumbers.isNotEmpty &&
      m.attempts > 0 &&
      m.attempts < CollectionSmsService.maxAutoAttempts;
  return switch (m.status) {
    SmsOutboxStatus.sent => ('Sent', BCollectionColors.success),
    SmsOutboxStatus.unconfirmed when retrying =>
      ('Retrying · try ${m.attempts + 1}', BCollectionColors.warning),
    SmsOutboxStatus.unconfirmed => ('Not confirmed', BCollectionColors.warning),
    SmsOutboxStatus.failed when retrying =>
      ('Retrying · try ${m.attempts + 1}', BCollectionColors.warning),
    SmsOutboxStatus.failed => ('Failed', BCollectionColors.danger),
    SmsOutboxStatus.handedOff => ('Opened in Messages', BCollectionColors.info),
    SmsOutboxStatus.noRecipients => ('Nobody to text', BCollectionColors.danger),
    _ => ('Sending', BCollectionColors.neutral),
  };
}

(String, IconData, Color) _recipientLabel(String result) => switch (result) {
      SmsRecipientResult.sent =>
        ('Sent', Iconsax.tick_circle, BCollectionColors.success),
      SmsRecipientResult.unconfirmed =>
        ('Not confirmed', Iconsax.timer, BCollectionColors.warning),
      SmsRecipientResult.failed =>
        ('Failed', Iconsax.close_circle, BCollectionColors.danger),
      SmsRecipientResult.handedOff =>
        ('Opened in Messages', Iconsax.message, BCollectionColors.info),
      _ => ('Waiting', Iconsax.clock, BCollectionColors.neutral),
    };

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.message,
    required this.controller,
    required this.busy,
  });

  final SmsOutboxRecord message;
  final CollectionSmsOutboxController controller;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = _statusLabel(message);
    final canResend =
        message.needsAttention && message.unconfirmedNumbers.isNotEmpty;
    final thisOne = controller.resending.value == message.id;
    return Card(
      key: ValueKey('sms-outbox-${message.id}'),
      margin: const EdgeInsets.only(bottom: BSizes.spaceBtwItemsLight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
        side: BorderSide(color: BCollectionColors.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
        onTap: () => _showFull(context),
        child: Padding(
          padding: const EdgeInsets.all(BSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      [
                        if (message.kind.isNotEmpty) message.kind,
                        CollectionSmsOutboxScreen.when(message.createdAt),
                      ].join(' · '),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: BCollectionColors.inkMuted),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
                    ),
                    child: Text(label,
                        key: ValueKey('sms-outbox-status-${message.id}'),
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: color, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: BSizes.xs),
              Text(message.headline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: BSizes.xs),
              for (final r in message.recipients) _recipientRow(context, r),
              if (message.status == SmsOutboxStatus.noRecipients)
                Text(
                  'No Head with a number and no Collection contact were set '
                  'when this was sent. Set them in Settings, then discard it.',
                  style: theme.textTheme.bodySmall,
                ),
              if ((message.lastError ?? '').isNotEmpty && message.needsAttention)
                Padding(
                  padding: const EdgeInsets.only(top: BSizes.xs),
                  child: Text(message.lastError!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: BCollectionColors.inkSecondary)),
                ),
              if (message.needsAttention) ...[
                const SizedBox(height: BSizes.sm),
                Row(
                  children: [
                    if (canResend)
                      ElevatedButton.icon(
                        key: ValueKey('sms-outbox-resend-${message.id}'),
                        onPressed:
                            busy ? null : () => controller.resend(message.id),
                        icon: thisOne
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Iconsax.send_1, size: 18),
                        label: Text(message.unconfirmedNumbers.length ==
                                message.recipients.length
                            ? 'Send now'
                            : 'Send now to ${message.unconfirmedNumbers.length}'),
                      ),
                    const SizedBox(width: BSizes.sm),
                    TextButton(
                      key: ValueKey('sms-outbox-discard-${message.id}'),
                      onPressed: busy ? null : () => _confirmDiscard(context),
                      child: const Text('Discard'),
                    ),
                  ],
                ),
              ],
              // Sent: it can still be sent again, e.g. when the Head says it
              // never arrived.
              if (!message.needsAttention &&
                  message.recipients.isNotEmpty) ...[
                const SizedBox(height: BSizes.xs),
                Row(
                  children: [
                    if (message.attempts > 1 &&
                        (message.lastAttemptAt ?? '').isNotEmpty)
                      Expanded(
                        child: Text(
                          'Last sent '
                          '${CollectionSmsOutboxScreen.when(message.lastAttemptAt!)}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: BCollectionColors.inkMuted),
                        ),
                      )
                    else
                      const Spacer(),
                    TextButton.icon(
                      key: ValueKey('sms-outbox-resend-sent-${message.id}'),
                      onPressed: busy ? null : () => _confirmResend(context),
                      icon: thisOne
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Iconsax.refresh, size: 18),
                      label: const Text('Resend'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmResend(BuildContext context) async {
    final n = message.recipients.length;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resend this SMS?'),
        content: Text('The same message goes again to all $n '
            '${n == 1 ? 'recipient' : 'recipients'}, in the background.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              key: const ValueKey('sms-outbox-resend-sent-confirm'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Resend')),
        ],
      ),
    );
    if (yes == true) await controller.resendSent(message.id);
  }

  Widget _recipientRow(BuildContext context, SmsOutboxRecipient r) {
    final (label, icon, color) = _recipientLabel(r.result);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: BSizes.xs),
          Expanded(
              child: Text(r.number,
                  style: Theme.of(context).textTheme.bodySmall)),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showFull(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message.kind.isEmpty ? 'SMS' : message.kind),
        content: SingleChildScrollView(child: SelectableText(message.message)),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message.message));
              Navigator.of(context).pop();
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDiscard(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this SMS?'),
        content: const Text(
            'It will not be sent, and it leaves the outbox. The engagement '
            'itself is kept.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep')),
          TextButton(
              key: const ValueKey('sms-outbox-discard-confirm'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard')),
        ],
      ),
    );
    if (yes == true) await controller.discard(message.id);
  }
}
