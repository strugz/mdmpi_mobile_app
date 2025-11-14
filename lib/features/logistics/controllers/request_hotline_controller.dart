import 'package:get/get.dart';

class RequestHotlineController extends GetxController {
  static RequestHotlineController get instance => Get.find();

  final isLoading = false.obs;
  final isSaving = false.obs;
  final isFetchingRequests = false.obs;
  final useLocalStorage = true.obs;

}