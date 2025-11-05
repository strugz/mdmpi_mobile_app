import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/features/authentication/screens/login/login.dart';
import 'package:mdmpi_mobile_app/features/authentication/screens/password_configuration/forget_password.dart';
import 'package:mdmpi_mobile_app/features/authentication/screens/signup/signup.dart';
import 'package:mdmpi_mobile_app/features/authentication/screens/signup/verify_email.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/delivery_location/location_google.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/home.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/onboarding/onboarding.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_forms/widgets/air_sea_form.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_forms/widgets/hotline_direct_form.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_forms/widgets/pick_up_form.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_forms/widgets/pull_out_form.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_forms/widgets/standard_delivery_form.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_forms/widgets/stock_receive_form.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/address/add_new_address.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/profile/profile.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/settings/settings.dart';

import '../../../features/logistics/screens/request/request.dart';

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
    GetPage(name: BRoutes.onBoarding, page: () => const OnboardingScreen()),
    GetPage(name: BRoutes.request, page: () => const RequestScreen()),
    GetPage(name: BRoutes.location, page: () => const LocationPageGoogle()),
  ];

  // Pages to navigate to
  static final requestFormPages = [
    const StandardDelivery(),
    const AirSeaForm(),
    const HotlineDirectForm(),
    const PickUpForm(),
    const PullOutForm(),
    const StockReceiveForm(),
  ];
}
