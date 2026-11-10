import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/common/widgets/form/b_text_form_field.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/commute_id.dart';

/// Trip Ticket No field with a "Commuting" switch. A commuting driver has no
/// trip ticket: the switch fills the field with a server-issued Commute ID
/// (read-only) and clears the [vehicle] selection. Callers hide their Vehicle
/// field while [CommuteTicketToggle.isOn] is true.
class TripTicketInput extends StatelessWidget {
  const TripTicketInput({
    super.key,
    required this.tripTicket,
    required this.commute,
    this.vehicle,
    this.validator,
  });

  final TextEditingController tripTicket;
  final CommuteTicketToggle commute;
  final TextEditingController? vehicle;
  final String? Function(String?)? validator;

  Future<void> _onChanged(bool on) async {
    final error = await commute.setCommute(
      on,
      tripTicket: tripTicket,
      vehicle: vehicle,
    );
    if (error != null) {
      BLoaders.errorSnackBar(title: 'Commute ID', message: error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isOn = commute.isOn.value;
      final isIssuing = commute.isIssuing.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          BTextFormField(
            controller: tripTicket,
            label: isOn ? 'Commute ID' : 'Trip Ticket No',
            prefixIcon: isOn ? Iconsax.bus : Iconsax.ticket,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            readOnly: isOn || isIssuing,
            validator: validator,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: isOn,
            onChanged: isIssuing ? null : _onChanged,
            title: const Text('Commuting (no trip ticket)'),
            subtitle: isIssuing
                ? const Text('Getting a Commute ID…')
                : isOn
                    ? const Text('No vehicle needed')
                    : null,
          ),
        ],
      );
    });
  }
}
