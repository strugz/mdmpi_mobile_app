import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_ids.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';

/// Controller for the 'Air / Sea / Land HD' tab — the Hotline-Direct (urgent)
/// variant of the Air/Sea module.
///
/// It shares the whole Air/Sea stack (model, repository, DAO, data manager,
/// filter manager, form, modal config, status flow); the only difference is
/// [scope], which restricts this instance to rows whose FormCategoryID equals
/// FormCategoryIds.airSeaHd. Each instance builds its own managers in onInit,
/// so base and HD state never mix — mirroring how HotlineDirectController
/// sits beside StandardDeliveryController.
class AirSeaHdController extends AirSeaController {
  @override
  AirSeaCategoryScope get scope => AirSeaCategoryScope.hotlineDirect;
}

/// Resolves which Air/Sea controller instance owns a given request, so shared
/// detail pages/sections/dialogs act on (and refresh) the right tab's state.
class AirSeaControllers {
  AirSeaControllers._();

  static AirSeaController forRequest(AirSeaModel request) {
    if (AirSeaCategoryScope.hotlineDirect.matches(request.formCategoryID) &&
        Get.isRegistered<AirSeaHdController>()) {
      return Get.find<AirSeaHdController>();
    }
    return Get.find<AirSeaController>();
  }
}
