import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/app_routes.dart';
import 'package:mdmpi_mobile_app/base/utils/theme/theme.dart';
import 'package:mdmpi_mobile_app/bindings/app/general_bindings.dart';
import 'package:mdmpi_mobile_app/main.dart';

class App extends StatelessWidget {
  const App({super.key});



  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: BAppTheme.lightTheme,
      darkTheme: BAppTheme.darkTheme,
      initialBinding: GeneralBindings(),
      getPages: AppRoutes.pages,
      navigatorKey: navigatorKey,
      home: const Scaffold(
          backgroundColor: BColors.primary,
          body: Center(child: CircularProgressIndicator(color: Colors.white))),
    );

  }
}
