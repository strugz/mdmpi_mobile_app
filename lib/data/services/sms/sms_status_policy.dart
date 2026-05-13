import 'dart:collection';

import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';

/// Encapsulates which statuses trigger SMS notifications.
class SmsStatusPolicy {
  static final Set<String> _requiredStatuses = <String>{
    BTexts.statusNewRequest,
    BTexts.statusGettingSuppliesReady,
    BTexts.statusItemPrepared,
    BTexts.statusDoneDelivery,
    BTexts.statusCancelled,
    BTexts.statusItemPacked,
    BTexts.statusReceived,
    BTexts.statusInTransit,
    BTexts.statusTakenOut,
    BTexts.statusEndorsedToGuard,
    BTexts.statusForDispatch,
    BTexts.statusDispatch,
    BTexts.statusDropOff,
    BTexts.statusProvincialPickUp,
    BTexts.statusProvincialInTransit,
    BTexts.statusProvincialDelivered,
  };

  bool requiresSmsForStatus(String status) => _requiredStatuses.contains(status);

  UnmodifiableSetView<String> get requiredStatuses =>
      UnmodifiableSetView<String>(_requiredStatuses);
}

