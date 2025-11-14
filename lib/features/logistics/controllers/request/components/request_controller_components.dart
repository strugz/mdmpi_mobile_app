
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class RequestControllerComponents {
  static void showDateTimerPicker(
      BuildContext context, TextEditingController targetDate) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      targetDate.text = DateFormat('yyyy-MM-dd').format(pickedDate);
    }
  }
}
