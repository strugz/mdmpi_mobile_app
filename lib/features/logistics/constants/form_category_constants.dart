/// Constants for Form Categories used in the logistics module.
///
/// This enum provides a centralized, type-safe way to reference form categories
/// throughout the application, ensuring consistency between UI labels, database
/// queries, and navigation logic.
enum FormCategoryType {
  standardDelivery,
  pullOutReturn,
  pickUp,
  airSea,
  hotlineDirect,
  stockReceive,
}

/// Extension to provide display names and category name matching for FormCategoryType.
extension FormCategoryTypeExtension on FormCategoryType {
  /// Returns the display name as stored in the database.
  /// This should match the FormCategoryName field in the a_tblFormCategory table.
  String get categoryName {
    switch (this) {
      case FormCategoryType.standardDelivery:
        return 'Standard Delivery';
      case FormCategoryType.pullOutReturn:
        return 'Pull Out / Return';
      case FormCategoryType.pickUp:
        return 'Pick Up';
      case FormCategoryType.airSea:
        // Renamed from 'Air / Sea' (2026-09-04). Must match the server's
        // a_tblcategory row (type='Form') — rename both in lockstep.
        return 'Air / Sea / Land';
      case FormCategoryType.hotlineDirect:
        return 'Hotline Direct';
      case FormCategoryType.stockReceive:
        return 'Stock Receive';
    }
  }

  /// Returns the lowercase version for case-insensitive matching.
  String get lowerCaseName => categoryName.toLowerCase();

  /// Former display names still accepted when matching server data, so the
  /// app keeps working while the server row rename deploys.
  List<String> get legacyNames {
    switch (this) {
      case FormCategoryType.airSea:
        return const ['Air / Sea']; // renamed to 'Air / Sea / Land' 2026-09-04
      default:
        return const [];
    }
  }

  /// Returns the index position in AppRoutes.requestFormPages.
  /// This determines which form page to navigate to.
  int get formPageIndex {
    switch (this) {
      case FormCategoryType.standardDelivery:
        return 0;
      case FormCategoryType.pullOutReturn:
        return 1;
      case FormCategoryType.pickUp:
        return 2;
      case FormCategoryType.airSea:
        return 3;
      case FormCategoryType.hotlineDirect:
        return 4;
      case FormCategoryType.stockReceive:
        return 5;
    }
  }

  /// Returns the actual form page index to use for navigation.
  /// Some categories share the same form (e.g., Stock Receive uses Pull Out form).
  int get actualFormPageIndex {
    switch (this) {
      case FormCategoryType.standardDelivery:
        return 0; // StandardDelivery()
      case FormCategoryType.pullOutReturn:
        return 1; // PullOutForm()
      case FormCategoryType.pickUp:
        return 2; // PickUpForm()
      case FormCategoryType.airSea:
        return 3; // AirSeaForm()
      case FormCategoryType.hotlineDirect:
        return 0; // Uses StandardDelivery()
      case FormCategoryType.stockReceive:
        return 1; // Uses PullOutForm()
    }
  }

  /// Returns true if this category uses a shared form from another category.
  bool get usesSharedForm {
    return this == FormCategoryType.hotlineDirect ||
        this == FormCategoryType.stockReceive;
  }

  /// Returns the category type that this category's form is based on.
  FormCategoryType get baseFormCategory {
    switch (this) {
      case FormCategoryType.hotlineDirect:
        return FormCategoryType.standardDelivery;
      case FormCategoryType.stockReceive:
        return FormCategoryType.pullOutReturn;
      default:
        return this;
    }
  }
}

/// Helper class to work with FormCategoryType and category names.
class FormCategoryConstants {
  FormCategoryConstants._(); // Private constructor to prevent instantiation

  /// Returns all form category types in their display order.
  static List<FormCategoryType> get allCategories => FormCategoryType.values;

  /// Returns all category names in their display order.
  static List<String> get allCategoryNames =>
      FormCategoryType.values.map((e) => e.categoryName).toList();

  /// Finds a FormCategoryType by matching the category name (case-insensitive).
  /// Legacy display names (see [FormCategoryTypeExtension.legacyNames]) are
  /// accepted too, so renames deploy without breaking older server data.
  static FormCategoryType? fromCategoryName(String name) {
    final lower = name.toLowerCase();
    try {
      return FormCategoryType.values.firstWhere(
        (type) =>
            type.lowerCaseName == lower ||
            type.legacyNames.any((legacy) => legacy.toLowerCase() == lower),
      );
    } catch (_) {
      return null;
    }
  }

  /// Finds a FormCategoryType by its form page index.
  static FormCategoryType? fromIndex(int index) {
    try {
      return FormCategoryType.values.firstWhere(
        (type) => type.formPageIndex == index,
      );
    } catch (_) {
      return null;
    }
  }

  /// Checks if a category name matches any of the form categories.
  static bool isValidCategoryName(String name) {
    return fromCategoryName(name) != null;
  }

  /// Returns the form page index for a given category name.
  static int? getFormPageIndex(String categoryName) {
    final type = fromCategoryName(categoryName);
    return type?.actualFormPageIndex;
  }
}
