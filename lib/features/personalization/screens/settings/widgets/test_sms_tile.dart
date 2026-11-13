import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/common/widgets/list_tiles/settings_menu_tile.dart';
import 'package:mdmpi_mobile_app/data/services/collection_sms_service.dart';

/// Settings → Developer Tools → Test SMS Outbox (debug builds, Android).
///
/// Sends one message to a number typed here through the SMS Outbox, with
/// its real statuses and retries, then opens the Outbox to watch it. Never
/// texts the Head or the Collection contacts.
class TestSmsTile extends StatelessWidget {
  const TestSmsTile({super.key});

  static String defaultMessage() =>
      'Test SMS from MDMPI App, ${DateTime.now().toString().substring(0, 19)}';

  @override
  Widget build(BuildContext context) {
    return BSettingsMenuTile(
      key: const ValueKey('settings-test-sms'),
      icon: Iconsax.message_programming,
      title: 'Test SMS Outbox',
      subTitle: 'Send a test SMS to one number through the Outbox',
      onTap: () => _open(context),
    );
  }

  Future<void> _open(BuildContext context) async {
    final number = TextEditingController();
    final message = TextEditingController(text: defaultMessage());
    final send = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test SMS Outbox'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('test-sms-number'),
                controller: number,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Send to', hintText: '09xx xxx xxxx'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('test-sms-message'),
                controller: message,
                minLines: 2,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Goes only to this number. Your initials are added at the end, '
                'as on every Collection SMS.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Send')),
        ],
      ),
    );
    final to = number.text.trim();
    final text = message.text.trim();
    if (send != true) return;
    if (to.isEmpty || text.isEmpty) {
      Get.snackbar('Test SMS', 'Enter a number and a message.');
      return;
    }
    if (!Get.isRegistered<CollectionSmsService>()) {
      Get.snackbar('Test SMS', 'The SMS service is not running.');
      return;
    }
    // ignore: unawaited_futures
    CollectionSmsService.instance.sendTest(number: to, message: text);
    Get.toNamed(BRoutes.collectionSmsOutbox);
  }
}
