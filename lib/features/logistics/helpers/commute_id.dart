import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/repositories/app_data/commute_id_repository.dart';

/// Commute IDs fill the Trip Ticket Number when a driver commutes (no company
/// vehicle, so no trip ticket): `yyyyMMdd` + a 4-digit daily sequence issued
/// by MDMPI.App, e.g. `202610200001`.
class BCommuteId {
  BCommuteId._();

  static final RegExp _pattern = RegExp(r'^(\d{4})(\d{2})(\d{2})(\d{4})$');

  /// True when [value] is a Commute ID: 12 digits whose first 8 are a real
  /// calendar date and whose sequence is at least 0001. Real trip tickets are
  /// short numbers (`01019`), so they never match.
  static bool isCommuteId(String? value) {
    final match = _pattern.firstMatch(value?.trim() ?? '');
    if (match == null) return false;

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final seq = int.parse(match.group(4)!);
    if (year < 2000 || month < 1 || month > 12 || day < 1 || seq < 1) {
      return false;
    }
    final date = DateTime(year, month, day);
    return date.month == month && date.day == day;
  }

  /// Label for a stored trip ticket value in read-only views.
  static String label(String? value) =>
      isCommuteId(value) ? 'Commute ID' : 'Trip Ticket No';
}

/// The "Commuting" switch beside a Trip Ticket No field.
///
/// Turning it on asks the server for a Commute ID, writes it into the trip
/// ticket field, and clears the vehicle (a commuter has none). Turning it off
/// clears the field for a typed trip ticket. An ID already issued in this form
/// session is reused if the switch is flipped again, so toggling does not use
/// up numbers.
class CommuteTicketToggle {
  CommuteTicketToggle({Future<Result<String>> Function()? issue})
      : _issue = issue ?? (() => CommuteIdRepository.instance.issue());

  final Future<Result<String>> Function() _issue;

  final RxBool isOn = false.obs;
  final RxBool isIssuing = false.obs;
  String _issuedId = '';

  /// Returns an error message when no Commute ID could be issued (the switch
  /// stays off), otherwise null.
  Future<String?> setCommute(
    bool on, {
    required TextEditingController tripTicket,
    TextEditingController? vehicle,
  }) async {
    if (isIssuing.value) return null;

    if (!on) {
      isOn.value = false;
      tripTicket.clear();
      return null;
    }

    if (_issuedId.isEmpty) {
      isIssuing.value = true;
      try {
        final result = await _issue();
        if (result.isFailure) return result.error;
        _issuedId = result.value;
      } finally {
        isIssuing.value = false;
      }
    }

    tripTicket.text = _issuedId;
    vehicle?.clear();
    isOn.value = true;
    return null;
  }

  /// Back to a typed trip ticket; forgets the issued ID (call after the
  /// request is saved, when the ID has been used).
  void reset() {
    isOn.value = false;
    isIssuing.value = false;
    _issuedId = '';
  }
}
