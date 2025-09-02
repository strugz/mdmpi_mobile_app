import 'package:url_launcher/url_launcher.dart';

import 'helper_functions.dart';

class CallFunctions {
  static void makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber.replaceRange(0, 1, '+63'),
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Handle the error, e.g., show a snack bar
      BHelperFunctions.showSnackBar(
          'Could not launch phone call to $phoneNumber');
      // Or if you want to be more specific about why it failed:
      // print('Could not launch $launchUri');
    }
  }
}
