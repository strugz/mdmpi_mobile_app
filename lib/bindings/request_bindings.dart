import 'package:get/get.dart';

class RequestBindings extends Bindings {
  @override
  void dependencies() {
    // Intentionally empty: RequestController and shared controllers are registered
    // centrally in `GeneralBindings`. Keep this class as a route-specific
    // placeholder for future registrations if needed.
  }
}
