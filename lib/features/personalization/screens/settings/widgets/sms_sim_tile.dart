import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:mdmpi_mobile_app/common/widgets/list_tiles/settings_menu_tile.dart';
import 'package:mdmpi_mobile_app/data/services/sim_info_service.dart';

/// Settings → SMS SIM: the SIM slot, carrier and number the app's SMS go out
/// from (the phone's default SMS SIM). Tap to refresh after changing it.
class SmsSimTile extends StatefulWidget {
  const SmsSimTile({super.key});

  @override
  State<SmsSimTile> createState() => _SmsSimTileState();
}

class _SmsSimTileState extends State<SmsSimTile> {
  final _service = Get.find<SimInfoService>();
  SimInfoAccess? _access;
  String? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool request = false}) async {
    final access = await _service.access(request: request);
    String? summary;
    if (access == SimInfoAccess.granted) {
      final result = await _service.defaultSmsSim();
      summary = result.fold(onSuccess: (sim) => sim.summary, onFailure: (e) => e);
    }
    if (!mounted) return;
    setState(() {
      _access = access;
      _summary = summary;
    });
  }

  Future<void> _onTap() async {
    if (_access == SimInfoAccess.blocked) {
      await openAppSettings();
    }
    await _load(request: true);
  }

  @override
  Widget build(BuildContext context) {
    final subTitle = switch (_access) {
      SimInfoAccess.granted => _summary ?? 'Checking…',
      SimInfoAccess.denied => 'Tap to allow phone access and show the SMS SIM',
      SimInfoAccess.blocked =>
        'Phone access blocked · tap to allow it in the phone settings',
      SimInfoAccess.unsupported => 'Not available on this device',
      null => 'Checking…',
    };
    return BSettingsMenuTile(
      key: const ValueKey('settings-sms-sim'),
      icon: Iconsax.simcard,
      title: 'SMS SIM',
      subTitle: subTitle,
      onTap: _onTap,
    );
  }
}
