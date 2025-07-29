// This file contains application-wide constants that define the app's design system.
// These constants ensure consistency across the UI and make it easy to maintain design changes.
// This demonstrates proper constant organization and design system management.

import 'package:flutter/material.dart';

/// Application-wide constants that define the design system and configuration.
/// These constants ensure consistency across the entire app and make maintenance easier.
class AppConstants {
  // Private constructor to prevent instantiation (constant class)
  AppConstants._();

  // MARK: - Spacing Constants
  /// Extra small spacing used for minimal gaps between elements.
  /// Example: spacing between icon and text in a button.
  static const double paddingXS = 4.0;

  /// Small spacing used for minor gaps between related elements.
  /// Example: spacing between items in a list.
  static const double paddingS = 8.0;

  /// Medium spacing used for standard gaps between UI elements.
  /// Example: padding inside cards and containers.
  static const double paddingM = 16.0;

  /// Large spacing used for major gaps between sections.
  /// Example: spacing between different sections on a screen.
  static const double paddingL = 24.0;

  /// Extra large spacing used for significant gaps between major sections.
  /// Example: spacing between the header and main content.
  static const double paddingXL = 32.0;

  /// Maximum spacing used for the largest gaps in the app.
  /// Example: spacing between completely separate sections.
  static const double paddingXXL = 48.0;

  // MARK: - Border Radius Constants
  /// Small border radius for subtle rounded corners.
  /// Example: small buttons or input fields.
  static const double radiusS = 4.0;

  /// Medium border radius for standard rounded corners.
  /// Example: cards and standard buttons.
  static const double radiusM = 8.0;

  /// Large border radius for prominent rounded corners.
  /// Example: large cards and prominent buttons.
  static const double radiusL = 12.0;

  /// Extra large border radius for very rounded corners.
  /// Example: floating action buttons and dialogs.
  static const double radiusXL = 16.0;

  /// Maximum border radius for fully rounded elements.
  /// Example: circular avatars and pills.
  static const double radiusXXL = 24.0;

  // MARK: - Height Constants
  /// Standard height for buttons and interactive elements.
  /// Ensures consistent touch targets across the app.
  static const double heightButton = 48.0;

  /// Height for small buttons and secondary interactive elements.
  /// Used for less prominent actions.
  static const double heightButtonSmall = 36.0;

  /// Height for input fields and text areas.
  /// Provides comfortable text input experience.
  static const double heightInput = 56.0;

  /// Height for list items and cards.
  /// Ensures consistent list item sizing.
  static const double heightListItem = 72.0;

  /// Height for app bar and navigation elements.
  /// Standard height for top navigation bars.
  static const double heightAppBar = 56.0;

  /// Height for bottom navigation bar.
  /// Standard height for bottom navigation.
  static const double heightBottomNav = 80.0;

  /// Height for floating action button.
  /// Standard size for FAB elements.
  static const double heightFAB = 56.0;

  /// Height for small floating action button.
  /// Used for secondary FAB elements.
  static const double heightFABSmall = 40.0;

  /// Height for pie chart visualization.
  /// Standard height for chart components.
  static const double height120 = 120.0;

  /// Height for medium chart visualization.
  /// Used for larger chart components.
  static const double height220 = 220.0;

  /// Height for legend components.
  /// Standard height for chart legends.
  static const double height56 = 56.0;

  // MARK: - Width Constants
  /// Standard width for buttons and interactive elements.
  /// Ensures consistent button sizing.
  static const double widthButton = 120.0;

  /// Width for small buttons and secondary elements.
  /// Used for less prominent actions.
  static const double widthButtonSmall = 80.0;

  /// Width for input fields.
  /// Standard width for text inputs.
  static const double widthInput = 200.0;

  /// Width for dialog boxes.
  /// Standard width for modal dialogs.
  static const double widthDialog = 300.0;

  /// Width for small dialog boxes.
  /// Used for simple confirmation dialogs.
  static const double widthDialogSmall = 250.0;

  // MARK: - Color Constants
  /// Primary color used throughout the app.
  /// Main brand color for primary actions and branding.
  static const int primaryColor = 0xFF2196F3;

  /// Secondary color used for secondary actions.
  /// Complementary color for secondary elements.
  static const int secondaryColor = 0xFF03DAC6;

  /// Success color for positive actions and states.
  /// Used for success messages, positive balances, etc.
  static const int successColor = 0xFF4CAF50;

  /// Warning color for cautionary states.
  /// Used for warnings, alerts, and attention-grabbing elements.
  static const int warningColor = 0xFFFF9800;

  /// Error color for negative actions and states.
  /// Used for errors, negative balances, and destructive actions.
  static const int errorColor = 0xFFF44336;

  /// Info color for informational states.
  /// Used for informational messages and neutral states.
  static const int infoColor = 0xFF2196F3;

  /// Background color for the app.
  /// Main background color for screens and containers.
  static const int backgroundColor = 0xFFF5F5F5;

  /// Surface color for cards and elevated elements.
  /// Color for cards, dialogs, and elevated surfaces.
  static const int surfaceColor = 0xFFFFFFFF;

  /// Text color for primary text.
  /// Main text color for headings and important text.
  static const int textColorPrimary = 0xFF212121;

  /// Text color for secondary text.
  /// Color for subtitles, captions, and less important text.
  static const int textColorSecondary = 0xFF757575;

  /// Text color for disabled text.
  /// Color for disabled or inactive text elements.
  static const int textColorDisabled = 0xFFBDBDBD;

  // MARK: - Animation Constants
  /// Duration for quick animations.
  /// Used for micro-interactions and quick feedback.
  static const Duration animationFast = Duration(milliseconds: 150);

  /// Duration for standard animations.
  /// Used for most UI transitions and state changes.
  static const Duration animationNormal = Duration(milliseconds: 300);

  /// Duration for slow animations.
  /// Used for complex transitions and loading states.
  static const Duration animationSlow = Duration(milliseconds: 500);

  /// Duration for very slow animations.
  /// Used for dramatic transitions and special effects.
  static const Duration animationVerySlow = Duration(milliseconds: 800);

  // MARK: - Text Size Constants
  /// Extra small text size for captions and fine print.
  /// Used for legal text, timestamps, and metadata.
  static const double textSizeXS = 10.0;

  /// Small text size for secondary information.
  /// Used for subtitles, captions, and secondary text.
  static const double textSizeS = 12.0;

  /// Medium text size for body text.
  /// Used for main content and readable text.
  static const double textSizeM = 14.0;

  /// Large text size for headings.
  /// Used for section headers and important text.
  static const double textSizeL = 16.0;

  /// Extra large text size for main headings.
  /// Used for page titles and major headings.
  static const double textSizeXL = 20.0;

  /// Maximum text size for prominent headings.
  /// Used for app titles and very important headings.
  static const double textSizeXXL = 24.0;

  // MARK: - Icon Size Constants
  /// Extra small icon size for minimal icons.
  /// Used for status indicators and small decorative icons.
  static const double iconSizeXS = 12.0;

  /// Small icon size for secondary icons.
  /// Used for list item icons and secondary actions.
  static const double iconSizeS = 16.0;

  /// Medium icon size for standard icons.
  /// Used for most UI icons and interactive elements.
  static const double iconSizeM = 20.0;

  /// Large icon size for prominent icons.
  /// Used for primary actions and important icons.
  static const double iconSizeL = 24.0;

  /// Extra large icon size for very prominent icons.
  /// Used for app icons and major visual elements.
  static const double iconSizeXL = 32.0;

  /// Maximum icon size for the largest icons.
  /// Used for splash screens and very prominent elements.
  static const double iconSizeXXL = 48.0;

  // MARK: - Shadow Constants
  /// Small shadow for subtle elevation.
  /// Used for cards and slightly elevated elements.
  static const double shadowS = 2.0;

  /// Medium shadow for standard elevation.
  /// Used for dialogs and moderately elevated elements.
  static const double shadowM = 4.0;

  /// Large shadow for prominent elevation.
  /// Used for floating elements and highly elevated surfaces.
  static const double shadowL = 8.0;

  /// Extra large shadow for maximum elevation.
  /// Used for modals and the most elevated elements.
  static const double shadowXL = 16.0;

  // MARK: - App Configuration Constants
  /// Maximum number of items to load at once in lists.
  /// Used for pagination and performance optimization.
  static const int maxItemsPerPage = 50;

  /// Maximum number of categories a user can create.
  /// Prevents UI clutter and maintains performance.
  static const int maxCategories = 20;

  /// Maximum length for expense descriptions.
  /// Prevents overly long descriptions that could break UI.
  static const int maxDescriptionLength = 100;

  /// Maximum amount for a single expense.
  /// Prevents unrealistic or erroneous expense entries.
  static const double maxExpenseAmount = 1000000.0;

  /// Minimum amount for a single expense.
  /// Ensures expenses have meaningful values.
  static const double minExpenseAmount = 0.01;

  /// Number of days to show in recent expenses.
  /// Used for "recent" expense filtering.
  static const int recentExpensesDays = 30;

  /// Number of months to show in expense history.
  /// Used for historical data display.
  static const int expenseHistoryMonths = 12;

  // MARK: - Validation Constants
  /// Minimum length for expense titles.
  /// Ensures expenses have meaningful titles.
  static const int minTitleLength = 1;

  /// Maximum length for expense titles.
  /// Prevents overly long titles that could break UI.
  static const int maxTitleLength = 50;

  /// Minimum length for category names.
  /// Ensures categories have meaningful names.
  static const int minCategoryNameLength = 1;

  /// Maximum length for category names.
  /// Prevents overly long category names that could break UI.
  static const int maxCategoryNameLength = 20;

  // MARK: - Cache Constants
  /// Duration to cache expense data in memory.
  /// Balances performance with data freshness.
  static const Duration cacheDuration = Duration(minutes: 5);

  /// Maximum number of cached expenses.
  /// Prevents excessive memory usage.
  static const int maxCachedExpenses = 1000;

  /// Duration to cache category data in memory.
  /// Categories change less frequently than expenses.
  static const Duration categoryCacheDuration = Duration(hours: 1);

  // MARK: - Animation Curves
  /// Standard easing curve for most animations.
  /// Provides smooth and natural motion.
  static const Curve animationCurve = Curves.easeInOut;

  /// Fast easing curve for quick animations.
  /// Used for micro-interactions and immediate feedback.
  static const Curve animationCurveFast = Curves.easeOut;

  /// Slow easing curve for dramatic animations.
  /// Used for important transitions and special effects.
  static const Curve animationCurveSlow = Curves.easeInOutCubic;

  // MARK: - Error Messages
  /// Default error message for network failures.
  /// Shown when network requests fail.
  static const String networkErrorMessage =
      'Network error. Please check your connection.';

  /// Default error message for data loading failures.
  /// Shown when data cannot be loaded.
  static const String dataLoadErrorMessage =
      'Failed to load data. Please try again.';

  /// Default error message for save failures.
  /// Shown when data cannot be saved.
  static const String saveErrorMessage =
      'Failed to save data. Please try again.';

  /// Default error message for validation failures.
  /// Shown when user input is invalid.
  static const String validationErrorMessage =
      'Please check your input and try again.';

  // MARK: - Success Messages
  /// Default success message for data saves.
  /// Shown when data is successfully saved.
  static const String saveSuccessMessage = 'Data saved successfully.';

  /// Default success message for data updates.
  /// Shown when data is successfully updated.
  static const String updateSuccessMessage = 'Data updated successfully.';

  /// Default success message for data deletions.
  /// Shown when data is successfully deleted.
  static const String deleteSuccessMessage = 'Data deleted successfully.';
}
