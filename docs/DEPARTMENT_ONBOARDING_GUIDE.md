# Department-Specific Onboarding Implementation Guide

**Date:** January 16, 2026  
**Status:** ✅ Logistics Complete | 🔜 Other Departments Ready to Implement  
**Current Issue:** RESOLVED - AppRouter now checks user department

---

## 🎯 Current Status

### ✅ **What's Already Done:**

1. ✅ **Logistics Onboarding** - Complete and working
   - Location: `features/logistics/screens/onboarding/`
   - Controller: `features/logistics/presentation/controllers/logistics_onboarding_controller.dart`
   - Storage Key: `LogisticsOnboardingComplete`

2. ✅ **AppRouter** - Department-aware routing
   - Checks `UserDepartment` from storage
   - Routes to department-specific onboarding
   - Falls back to NavigationMenu if onboarding complete

---

## 📁 Current Structure

```
features/
└── logistics/
    ├── presentation/
    │   └── controllers/
    │       └── logistics_onboarding_controller.dart  ✅ DONE
    └── screens/
        └── onboarding/
            ├── onboarding.dart                       ✅ DONE (Logistics-specific)
            └── widgets/
                ├── onboarding_page.dart
                ├── onboarding_skip.dart
                ├── onboarding_next_button.dart
                └── onboarding_dot_navigation.dart
```

---

## 🚀 How to Add Onboarding for Other Departments

### Step-by-Step Guide for Each Department

---

## 📦 **Collection Department**

### 1. Create Text Constants

**File:** `lib/base/utils/constants/text_string.dart`

Add collection-specific onboarding text:

```dart
// Collection Onboarding Texts
static const String collectionOnBoardingTitle1 = "Welcome to MDMPI APP - Collection!";
static const String collectionOnBoardingSubTitle1 = "Streamline your collection operations...";

static const String collectionOnBoardingTitle2 = "Track Collections";
static const String collectionOnBoardingSubTitle2 = "Monitor and manage all your collection tasks...";

static const String collectionOnBoardingTitle3 = "Optimize Routes";
static const String collectionOnBoardingSubTitle3 = "Efficient route planning for collection teams...";
```

### 2. Create Collection Onboarding Controller

**File:** `features/collection/presentation/controllers/collection_onboarding_controller.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/navigation_menu.dart';

/// Collection department onboarding controller
class CollectionOnboardingController extends GetxController {
  static CollectionOnboardingController get instance => Get.find();

  final PageController pageController = PageController();
  Rx<int> currentPageIndex = 0.obs;

  void updatePageIndicator(int index) => currentPageIndex.value = index;

  void dotNavigationClick(int index) {
    currentPageIndex.value = index;
    pageController.jumpTo(index.toDouble());
  }

  void nextPage() {
    if (currentPageIndex.value == 2) {
      final storage = GetStorage();
      storage.write('IsFirstTime', false);
      storage.write('CollectionOnboardingComplete', true); // ✅ Department-specific
      Get.offAll(() => const NavigationMenu());
    } else {
      int page = currentPageIndex.value + 1;
      pageController.jumpToPage(page);
    }
  }

  void skipPage() {
    currentPageIndex.value = 2;
    if (currentPageIndex.value == 2) {
      final storage = GetStorage();
      storage.write('IsFirstTime', false);
      storage.write('CollectionOnboardingComplete', true); // ✅ Department-specific
      Get.offAll(() => const NavigationMenu());
    }
  }
  
  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
```

### 3. Create Collection Onboarding Screen

**File:** `features/collection/screens/onboarding/collection_onboarding.dart`

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_onboarding_controller.dart';
// Reuse logistics widgets (they're generic enough)
import 'package:mdmpi_mobile_app/features/logistics/screens/onboarding/widgets/onboarding_dot_navigation.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/onboarding/widgets/onboarding_next_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/onboarding/widgets/onboarding_page.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/onboarding/widgets/onboarding_skip.dart';

class CollectionOnboardingScreen extends StatelessWidget {
  const CollectionOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CollectionOnboardingController>();
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: controller.pageController,
            onPageChanged: controller.updatePageIndicator,
            children: [
              OnBoardingPage(
                image: BImages.darkAppLogo,
                title: BTexts.collectionOnBoardingTitle1, // ✅ Collection-specific
                subtitle: BTexts.collectionOnBoardingSubTitle1,
              ),
              OnBoardingPage(
                image: BImages.onBoardingImage1, // Or collection-specific image
                title: BTexts.collectionOnBoardingTitle2,
                subtitle: BTexts.collectionOnBoardingSubTitle2,
              ),
              OnBoardingPage(
                image: BImages.onBoardingImage2, // Or collection-specific image
                title: BTexts.collectionOnBoardingTitle3,
                subtitle: BTexts.collectionOnBoardingSubTitle3,
              ),
            ],
          ),
          const OnBoardingSkip(),
          const OnBoardingDotNavigation(),
          const OnBoardingNextButton()
        ],
      ),
    );
  }
}
```

**Note:** The widgets (skip, next, dot navigation) are generic and can be reused!

### 4. Update Widgets to Use Generic Controller

**Option A:** Make widgets use GetxController base type (best)
**Option B:** Create collection-specific widgets (more work)

For simplicity, you can update the widgets to accept a controller parameter or use a generic interface.

### 5. Register in Bindings

**File:** `lib/bindings/general_bindings.dart`

```dart
import '../features/collection/presentation/controllers/collection_onboarding_controller.dart';

// In dependencies()
Get.lazyPut(() => CollectionOnboardingController(), fenix: true);
```

### 6. Update AppRouter

**File:** `lib/app_router.dart`

```dart
import 'package:mdmpi_mobile_app/features/collection/screens/onboarding/collection_onboarding.dart';

// In build method - already done! ✅
case 'Collection':
  final collectionComplete = storage.read('CollectionOnboardingComplete') ?? false;
  if (!collectionComplete) {
    return const CollectionOnboardingScreen(); // ✅ Now uncomment this
  }
  break;
```

---

## 🛠️ **Service Department**

Follow the same pattern as Collection:

1. Add service text constants
2. Create `ServiceOnboardingController`
3. Create `ServiceOnboardingScreen`
4. Register in bindings
5. Uncomment in AppRouter

---

## 🏢 **InHouse Department**

Follow the same pattern as Collection:

1. Add inhouse text constants
2. Create `InHouseOnboardingController`
3. Create `InHouseOnboardingScreen`
4. Register in bindings
5. Uncomment in AppRouter

---

## 📊 Final Structure (All Departments)

```
features/
├── logistics/
│   ├── presentation/
│   │   └── controllers/
│   │       └── logistics_onboarding_controller.dart  ✅
│   └── screens/
│       └── onboarding/
│           ├── onboarding.dart                       ✅
│           └── widgets/                              ✅ (Reusable)
│               ├── onboarding_page.dart
│               ├── onboarding_skip.dart
│               ├── onboarding_next_button.dart
│               └── onboarding_dot_navigation.dart
│
├── collection/
│   ├── presentation/
│   │   └── controllers/
│   │       └── collection_onboarding_controller.dart  🔜
│   └── screens/
│       └── onboarding/
│           └── collection_onboarding.dart            🔜
│
├── service/
│   ├── presentation/
│   │   └── controllers/
│   │       └── service_onboarding_controller.dart    🔜
│   └── screens/
│       └── onboarding/
│           └── service_onboarding.dart               🔜
│
└── inhouse/
    ├── presentation/
    │   └── controllers/
    │       └── inhouse_onboarding_controller.dart    🔜
    └── screens/
        └── onboarding/
            └── inhouse_onboarding.dart               🔜
```

---

## 🎯 Key Points

### ✅ **What's Generic and Reusable:**

1. **Onboarding Widgets** - Can be reused across all departments:
   - `onboarding_page.dart` ✅
   - `onboarding_skip.dart` ✅
   - `onboarding_next_button.dart` ✅
   - `onboarding_dot_navigation.dart` ✅

2. **Controller Pattern** - Same structure, different storage keys:
   ```dart
   storage.write('LogisticsOnboardingComplete', true);
   storage.write('CollectionOnboardingComplete', true);
   storage.write('ServiceOnboardingComplete', true);
   ```

3. **AppRouter Logic** - Already handles all departments ✅

### ⚠️ **What's Department-Specific:**

1. **Text Constants** - Each department has unique content
2. **Images** (optional) - Can use department-specific images
3. **Controller Instance** - Each department has its own controller
4. **Screen File** - Each department has its own screen file

---

## 🔄 How User Department is Set

### Current (Default):
```dart
// In AppRouter
final userDepartment = storage.read('UserDepartment') ?? 'Logistics';
```

### Future (From User Profile):
After authentication, set user department:

```dart
// In LoadingScreenController or after login
final userProfile = await getUserProfile();
storage.write('UserDepartment', userProfile.department);
// 'Logistics', 'Collection', 'Service', or 'InHouse'
```

---

## ✅ Quick Implementation Checklist

For each new department:

- [ ] Add department-specific text constants
- [ ] Create `{Department}OnboardingController`
- [ ] Create `{Department}OnboardingScreen`
- [ ] Register controller in bindings
- [ ] Uncomment/update AppRouter case
- [ ] Test the flow

---

## 🎊 Summary

**Current Status:**
- ✅ **Logistics Onboarding** - Complete and working
- ✅ **AppRouter** - Department-aware, ready for all departments
- 🔜 **Collection/Service/InHouse** - Structure ready, waiting for implementation

**You were right!** The onboarding screen is in the logistics folder, but now:
1. ✅ AppRouter checks user department
2. ✅ Routes to correct department-specific onboarding
3. ✅ Easy to add new departments following the pattern

**Next Action:** When you're ready to add Collection/Service/InHouse onboarding, just follow the steps above for each department!

---

**Last Updated:** January 16, 2026  
**Status:** ✅ Structure Ready for All Departments
