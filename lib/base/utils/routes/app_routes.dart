import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/bindings/features/request_bindings.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/pages/login/login.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/pages/password_configuration/forget_password.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/pages/signup/signup.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/pages/signup/verify_email.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/delivery_location/location_google.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/home.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/onboarding/onboarding.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_forms/widgets/air_sea_form.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_forms/widgets/hotline_direct_form.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_forms/widgets/pick_up_form.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_forms/widgets/pull_out_form.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_forms/widgets/standard_delivery_form.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_forms/widgets/stock_receive_form.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/back_load/backload_transaction_page.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/address/add_new_address.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/profile/profile.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/settings/image_outbox_page.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/settings/settings.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/settings/signature_outbox_page.dart';

import '../../../features/logistics/screens/request.dart';
import '../../../features/logistics/screens/data_test/local_storage_data_viewer.dart';

class AppRoutes {
  static final pages = [
    GetPage(name: BRoutes.home, page: () => const HomeScreen()),
    GetPage(name: BRoutes.settings, page: () => const SettingsScreen()),
    GetPage(name: BRoutes.userProfile, page: () => ProfileScreen()),
    GetPage(name: BRoutes.userAddress, page: () => const AddNewAddressScreen()),
    GetPage(name: BRoutes.signup, page: () => const SignupScreen()),
    GetPage(name: BRoutes.verifyEmail, page: () => const VerifyEmailScreen()),
    GetPage(name: BRoutes.signIn, page: () => const LoginScreen()),
    GetPage(name: BRoutes.forgetPassword, page: () => const ForgetPassword()),
    GetPage(
        name: BRoutes.onBoarding,
        page: () =>
            const OnBoardingScreen()), // TODO: Make department-specific routes (e.g., logisticsOnBoarding)
    GetPage(
        name: BRoutes.request,
        page: () => const RequestScreen(),
        binding: RequestBindings()),
    GetPage(name: BRoutes.location, page: () => const LocationPageGoogle()),
    GetPage(name: BRoutes.pullOutForm, page: () => const PullOutForm()),
    GetPage(
        name: BRoutes.localStorageViewer,
        page: () => const LocalStorageDataViewer()),
    GetPage(
        name: BRoutes.signatureOutbox, page: () => const SignatureOutboxPage()),
    GetPage(name: BRoutes.imageOutbox, page: () => const ImageOutboxPage()),
    // BackLoad receives the StandardDeliveryModel via Get.arguments
    GetPage(
      name: BRoutes.backLoad,
      page: () {
        final model = Get.arguments as StandardDeliveryModel;
        return BackLoadTransactionPage(requestModel: model);
      },
    ),
  ];

  // Pages to navigate to
  static final requestFormPages = [
    const StandardDelivery(),
    const PullOutForm(),
    const PickUpForm(),
    const AirSeaForm(),
    const HotlineDirectForm(),
    const StockReceiveForm(),
  ];
}
