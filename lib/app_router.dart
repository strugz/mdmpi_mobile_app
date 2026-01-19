import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/onboarding/onboarding.dart';
import 'package:mdmpi_mobile_app/navigation_menu.dart';

/// App Entry Point Router
///
/// Handles routing logic after authentication is complete.
/// Routes to department-specific onboarding based on user's department.
///
/// Checks user department and onboarding completion status:
/// - Logistics → Logistics Onboarding
/// - Collection → Collection Onboarding (future)
/// - Service → Service Onboarding (future)
/// - InHouse → InHouse Onboarding (future)
class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = GetStorage();

    // Get user department (default to Logistics for now)
    // TODO: Get this from user profile/authentication
    final userDepartment = storage.read('UserDepartment') ?? 'Logistics';

    // Check department-specific onboarding completion
    switch (userDepartment) {
      case 'Logistics':
        final logisticsComplete = storage.read('LogisticsOnboardingComplete') ?? false;
        if (!logisticsComplete) {
          return const OnBoardingScreen(); // Logistics onboarding
        }
        break;

      case 'Collection':
        final collectionComplete = storage.read('CollectionOnboardingComplete') ?? false;
        if (!collectionComplete) {
          // TODO: Create CollectionOnboardingScreen
          // return const CollectionOnboardingScreen();
          return const NavigationMenu(); // Temporary: skip to menu
        }
        break;

      case 'Service':
        final serviceComplete = storage.read('ServiceOnboardingComplete') ?? false;
        if (!serviceComplete) {
          // TODO: Create ServiceOnboardingScreen
          // return const ServiceOnboardingScreen();
          return const NavigationMenu(); // Temporary: skip to menu
        }
        break;

      case 'InHouse':
        final inhouseComplete = storage.read('InHouseOnboardingComplete') ?? false;
        if (!inhouseComplete) {
          // TODO: Create InHouseOnboardingScreen
          // return const InHouseOnboardingScreen();
          return const NavigationMenu(); // Temporary: skip to menu
        }
        break;

      default:
        // Unknown department - go to navigation
        break;
    }

    // Onboarding complete - go to main navigation
    return const NavigationMenu();
  }
}
