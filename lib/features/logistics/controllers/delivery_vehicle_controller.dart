import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/data/repositories/delivery_vehicle/delivery_vehicle_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/delivery_vehicle_model.dart';

class DeliveryVehicleController extends GetxController {
  static DeliveryVehicleController get instance => Get.find();

  final isLoading = false.obs;
  final _deliveryVehicleRepository = Get.find<DeliveryVehicleRepository>();
  RxList<DeliveryVehicleModel> allVehicleDelivery =
      <DeliveryVehicleModel>[].obs;
  final selectedVehicle = Rx<DeliveryVehicleModel?>(null);
  final selectedVehicleMarker = Rx<MarkerId?>(null);
  final destination = Rx<LatLng?>(null);
  final polylines = Rx<Set<Polyline>>({});
  final mapController = Rx<GoogleMapController?>(null);

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    fetchDeliveryVehicle();
  }

  /// --Get all Delivery Vehicle
  Future<void> fetchDeliveryVehicle() async {
    try {
      //  Show Loader while loading categories
      isLoading.value = true;

      //  Fetch delivery vehicle from data source (Firestore, API, etc.)
      final deliverVehicle = await _deliveryVehicleRepository.getALlVehicle();

      //  Update the deliveryVehicle list
      allVehicleDelivery.assignAll(deliverVehicle);
    } catch (e) {
      BLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    } finally {
      //  Remove Loader
      isLoading.value = false;
    }
  }
}
