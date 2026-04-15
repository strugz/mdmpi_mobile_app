import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';

/// Displays a single back-load remarks entry in a Card widget.
///
/// This is a pure UI widget — similar to [BCancelRemarks] but tailored
/// for the BackLoad flow (shows "Back Load" label and reason).
class BBackLoadRemarks extends StatelessWidget {
  const BBackLoadRemarks({
    super.key,
    required this.remarks,
    required this.dateReported,
  });

  final String remarks;
  final String dateReported;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textColor = dark ? BColors.light : BColors.black;

    String formattedDate;
    DateTime? dateTimeInstance;

    try {
      dateTimeInstance = DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateReported);
    } catch (_) {
      dateTimeInstance = DateTime.tryParse(dateReported);
    }

    formattedDate = dateTimeInstance != null
        ? DateFormat('MM/dd/yyyy hh:mm a').format(dateTimeInstance)
        : dateReported;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
          child: ListTile(
            leading: Icon(Icons.replay_outlined, color: textColor),
            title: Text(
              remarks,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              formattedDate,
              style: TextStyle(
                  color: textColor.withAlpha((0.7 * 255).round())),
            ),
            dense: true,
          ),
        ),
      ],
    );
  }
}

