import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';

/// Displays cancel remarks with formatted date in a Card widget.
///
/// This is a pure UI widget that shows cancellation information for
/// any logistics request (standard delivery, pull-out, etc.).
///
/// Supports multiple date formats and automatically formats them
/// to a user-friendly display format (MM/dd/yyyy hh:mm a).
class BCancelRemarks extends StatelessWidget {
  const BCancelRemarks({
    super.key,
    required this.remarks,
    required this.date,
    required this.user,
  });

  final String remarks;
  final String date;
  final String user;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textColor = dark ? BColors.light : BColors.black;

    String formattedDate;
    DateTime? dateTimeInstance;

    // Attempt to parse with the specific format "yyyy-MM-dd HH:mm:ss"
    try {
      dateTimeInstance = DateFormat("yyyy-MM-dd HH:mm:ss").parse(date);
    } catch (e) {
      // If specific format fails, try the more general DateTime.tryParse
      // which handles ISO 8601 and other common formats.
      dateTimeInstance = DateTime.tryParse(date);
    }

    if (dateTimeInstance != null) {
      // If parsing was successful (either way), format the date
      formattedDate = DateFormat("MM/dd/yyyy hh:mm a").format(dateTimeInstance);
    } else {
      // If all parsing attempts fail, fallback to the original date string
      formattedDate = date;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
          child: ListTile(
            leading: Icon(Icons.comment_outlined, color: textColor),
            title: Text(
              remarks,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user.isNotEmpty)
                  Text(
                    'Cancelled by: $user',
                    style: TextStyle(
                      color: textColor.withAlpha((0.7 * 255).round()),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                Text(
                  formattedDate,
                  style: TextStyle(color: textColor.withAlpha((0.7 * 255).round())),
                ),
              ],
            ),
            dense: true,
          ),
        )
      ],
    );
  }
}
