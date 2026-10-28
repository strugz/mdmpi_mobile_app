import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/daily_quote.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/daily_quote/daily_quote_dialog.dart';

/// The first time the app is opened each day, a small popup with today's
/// saying and verse: on Login when signed out, over Home (after any What's new) when
/// signed in. Once per day per phone, counted from when it is shown, so
/// closing the app with it open does not bring it back until tomorrow.
class DailyQuotePromptController extends GetxController {
  DailyQuotePromptController({GetStorage? storage, DateTime Function()? clock})
      : _storage = storage ?? GetStorage(),
        _clock = clock ?? DateTime.now;

  final GetStorage _storage;
  final DateTime Function() _clock;

  bool _showing = false;

  static const seenKey = 'DailyQuoteSeenDate';

  /// Not yet shown today.
  bool get isDue =>
      _storage.read<String>(seenKey) != BDailyQuotes.dateKey(_clock());

  Future<void> markSeen() =>
      _storage.write(seenKey, BDailyQuotes.dateKey(_clock()));

  Future<void> showIfDue() async {
    if (_showing || !isDue) return;
    _showing = true;
    try {
      await markSeen();
      final openTips = await Get.dialog<bool>(
          DailyQuoteDialog(today: BDailyQuotes.forDate(_clock())));
      if (openTips == true) Get.toNamed(BRoutes.quoteOfTheDay);
    } catch (e) {
      logDebug('DailyQuotePromptController: not shown: $e');
    } finally {
      _showing = false;
    }
  }
}
