import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BHelperFunctions {
  static Color? getColor(String value) {
    if (value == 'Green') {
      return Colors.green;
    } else if (value == 'Green') {
      return Colors.green;
    } else if (value == 'Red') {
      return Colors.red;
    } else if (value == 'Blue') {
      return Colors.blue;
    } else if (value == 'Pink') {
      return Colors.pink;
    } else if (value == 'Grey') {
      return Colors.grey;
    } else if (value == 'Purple') {
      return Colors.purple;
    } else if (value == 'Black') {
      return Colors.black;
    } else if (value == 'White') {
      return Colors.white;
    } else if (value == 'Brown') {
      return Colors.brown;
    } else if (value == 'Teal') {
      return Colors.teal;
    } else if (value == 'Indigo') {
      return Colors.indigo;
    } else if (value == 'Yellow') {
      return Colors.yellow;
    } else {
      return null;
    }
  }

  static void showSnackBar(String message) {
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static void showAlert(String title, String message) {
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }

  static void navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    } else {
      return '${text.substring(0, maxLength)}...';
    }
  }

  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Size screenSize() {
    return MediaQuery.of(Get.context!).size;
  }

  static double screenHeight() {
    return MediaQuery.of(Get.context!).size.height;
  }

  static double screenWidth() {
    return MediaQuery.of(Get.context!).size.width;
  }

  static String getFormatterDate(DateTime date,
      {String format = 'MM dd yyyy'}) {
    return DateFormat(format).format(date);
  }

  static List<T> removeDuplicates<T>(List<T> list) {
    return list.toSet().toList();
  }

  static List<Widget> wrapWidgets(List<Widget> widgets, int rowSize) {
    final wrappedList = <Widget>[];
    for (var i = 0; i < widgets.length; i += rowSize) {
      final rowChildren = widgets.sublist(
          i, i + rowSize > widgets.length ? widgets.length : i + rowSize);
      wrappedList.add(Row(children: rowChildren));
    }
    return wrappedList;
  }

  static String getUrl(String url) {
    if (url == 'sr') {
      return 'https://sr.mdmpi.com.ph';
    } else if (url == 'inventory') {
      return 'https://inventory.mdmpi.com.ph';
    } else if (url == 'fwms') {
      return 'https://fwms.mdmpi.com.ph';
    } else {
      return 'https://inventory.mdmpi.com.ph';
    }
  }


  static String getNextStatusForRelease(String currentStatus) {
    switch (currentStatus) {
      case "New Request":
        return "Getting supplies ready";
      case "Getting supplies ready":
        return "Item Prepared";
      case "Item Prepared":
        return "For Delivery";
      default:
        return currentStatus; // Or handle error/unknown status
    }
  }

  static Future<String?> pickDateString(BuildContext context, {bool includeTime = true}) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return null;
    if (includeTime) {
      final TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
      final DateTime combined = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? 0,
        pickedTime?.minute ?? 0,
      );
      return combined.toIso8601String();
    } else {
      return pickedDate.toIso8601String().split('T').first;
    }
  }

  /// Returns the length of a list-like object in a null-safe way.
  ///
  /// Supports:
  /// - RxList (GetX)
  /// - List / Iterable
  /// - Any object exposing a `length` property (attempted dynamically)
  ///
  /// Returns 0 for null or when the length cannot be determined.
  static int listCount(dynamic items) {
    if (items == null) return 0;

    try {
      if (items is RxList) return items.length;
      if (items is List) return items.length;
      if (items is Iterable) return items.length;

      // Fallback: try to read a dynamic `length` property
      final dynamic len = (items as dynamic).length;
      if (len is int) return len;
    } catch (_) {
      // ignore and return 0
    }

    return 0;
  }

}
