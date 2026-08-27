import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/onboarding/onboarding.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/user_model.dart';
import 'package:mdmpi_mobile_app/navigation_menu.dart';

import 'features/collection/presentation/pages/onboarding/onboarding.dart';

/// App Entry Point Router
///
/// Handles routing logic after authentication is complete.
/// Routes to department-specific onboarding based on user's department.
///
/// Reads department from [UserController] (primary) or cached [CurrentUser]
/// in [GetStorage] (fallback for cold start).
/// Checks user department and onboarding completion status:
/// - Logistics → Logistics Onboarding
/// - Collection → Collection Onboarding
/// - Service → Service Onboarding (future)
/// - InHouse → InHouse Onboarding (future)
class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = GetStorage();

    // Primary: read from UserController; fallback: cached CurrentUser in GetStorage
    String userDepartment = '';
    try {
      final userController = Get.find<UserController>();
      userDepartment = userController.user.value.department;
    } catch (_) {
      // UserController not yet registered (cold start)
    }
    if (userDepartment.isEmpty) {
      // Fallback: read full cached user from GetStorage
      try {
        final cachedJson = storage.read('CurrentUser');
        if (cachedJson != null && cachedJson is Map<String, dynamic>) {
          userDepartment = UserModel.fromJson(cachedJson).department;
        }
      } catch (_) {
        // Cached data corrupted or missing
      }
      // Legacy fallback (one-time migration for existing installs)
      if (userDepartment.isEmpty) {
        userDepartment = storage.read('UserDepartment') ?? '';
      }
    }

    // Check department-specific onboarding completion
    switch (userDepartment.trim().toLowerCase()) {
      case 'logistics':
        final logisticsComplete = storage.read('LogisticsOnboardingComplete') ?? false;
        if (!logisticsComplete) {
          return const OnBoardingScreen(); // Logistics onboarding
        }
        break;

      case 'collection':
        final collectionComplete = storage.read('CollectionOnboardingComplete') ?? false;
        if (!collectionComplete) {
          return const CollectionOnBoardingScreen();
        }
        break;

      case 'service':
        final serviceComplete = storage.read('ServiceOnboardingComplete') ?? false;
        if (!serviceComplete) {
          // TODO: Create ServiceOnboardingScreen
          return const NavigationMenu(); // Temporary: skip to menu
        }
        break;

      case 'inhouse':
        final inhouseComplete = storage.read('InHouseOnboardingComplete') ?? false;
        if (!inhouseComplete) {
          // TODO: Create InHouseOnboardingScreen
          return const NavigationMenu(); // Temporary: skip to menu
        }
        break;

      default:
        // Unknown or empty department - go to navigation
        break;
    }

    // Onboarding complete - go to main navigation
    return const NavigationMenu();
  }
}
