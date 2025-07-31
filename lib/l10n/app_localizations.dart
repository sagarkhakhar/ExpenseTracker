import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense Tracker'**
  String get appTitle;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get stats;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @editExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get editExpense;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @recurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurring;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @nextOccurrence.
  ///
  /// In en, this message translates to:
  /// **'Next Occurrence'**
  String get nextOccurrence;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date (optional)'**
  String get endDate;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @noExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get noExpenses;

  /// No description provided for @addFirstExpense.
  ///
  /// In en, this message translates to:
  /// **'Add your first expense to get started'**
  String get addFirstExpense;

  /// No description provided for @deleteExpense.
  ///
  /// In en, this message translates to:
  /// **'Delete Expense'**
  String get deleteExpense;

  /// No description provided for @deleteExpenseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this expense?'**
  String get deleteExpenseConfirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get manageCategories;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add new category'**
  String get addCategory;

  /// No description provided for @duplicateCategory.
  ///
  /// In en, this message translates to:
  /// **'Duplicate category name.'**
  String get duplicateCategory;

  /// No description provided for @categoryInUse.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete: Category is in use.'**
  String get categoryInUse;

  /// No description provided for @categoryNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Category name cannot be empty.'**
  String get categoryNameEmpty;

  /// No description provided for @enterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get enterTitle;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get enterAmount;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid category.'**
  String get selectCategory;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid, positive amount (max \$1,000,000).'**
  String get invalidAmount;

  /// No description provided for @incomeNegative.
  ///
  /// In en, this message translates to:
  /// **'Income cannot be negative.'**
  String get incomeNegative;

  /// No description provided for @selectFrequency.
  ///
  /// In en, this message translates to:
  /// **'Select a recurring frequency.'**
  String get selectFrequency;

  /// No description provided for @selectNextOccurrence.
  ///
  /// In en, this message translates to:
  /// **'Select next occurrence date.'**
  String get selectNextOccurrence;

  /// No description provided for @nextOccurrenceAfterDate.
  ///
  /// In en, this message translates to:
  /// **'Next occurrence must be after or equal to the main date.'**
  String get nextOccurrenceAfterDate;

  /// No description provided for @endDateAfterNext.
  ///
  /// In en, this message translates to:
  /// **'End date must be after next occurrence.'**
  String get endDateAfterNext;

  /// No description provided for @invalidData.
  ///
  /// In en, this message translates to:
  /// **'Invalid data. Please check all fields.'**
  String get invalidData;

  /// No description provided for @failedAdd.
  ///
  /// In en, this message translates to:
  /// **'Failed to add expense: {error}'**
  String failedAdd(Object error);

  /// No description provided for @failedEdit.
  ///
  /// In en, this message translates to:
  /// **'Failed to edit expense: {error}'**
  String failedEdit(Object error);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @errorLoadingExpenses.
  ///
  /// In en, this message translates to:
  /// **'Error loading expenses'**
  String get errorLoadingExpenses;

  /// No description provided for @smartTips.
  ///
  /// In en, this message translates to:
  /// **'Smart Tips'**
  String get smartTips;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data to display'**
  String get noData;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @dailyTrend.
  ///
  /// In en, this message translates to:
  /// **'Daily Cash Flow Trend'**
  String get dailyTrend;

  /// No description provided for @expensesByCategory.
  ///
  /// In en, this message translates to:
  /// **'Expenses by Category'**
  String get expensesByCategory;

  /// No description provided for @incomeByCategory.
  ///
  /// In en, this message translates to:
  /// **'Income by Category'**
  String get incomeByCategory;

  /// No description provided for @tipHighSpending.
  ///
  /// In en, this message translates to:
  /// **'You\'re spending over 80% of your income. Consider saving more this month.'**
  String get tipHighSpending;

  /// No description provided for @tipNoIncome.
  ///
  /// In en, this message translates to:
  /// **'No income recorded this month. Add your income to track your balance.'**
  String get tipNoIncome;

  /// No description provided for @tipCategorySpike.
  ///
  /// In en, this message translates to:
  /// **'High spending on \'{category}\'. Consider reviewing this category.'**
  String tipCategorySpike(Object category);

  /// No description provided for @tipNegativeBalance.
  ///
  /// In en, this message translates to:
  /// **'Your balance is negative. Try to reduce expenses or increase income.'**
  String get tipNegativeBalance;

  /// No description provided for @tipFewExpenses.
  ///
  /// In en, this message translates to:
  /// **'Add more expenses to get better insights and tips.'**
  String get tipFewExpenses;

  /// No description provided for @tipAllGood.
  ///
  /// In en, this message translates to:
  /// **'Great job! Your spending is under control this month.'**
  String get tipAllGood;

  /// No description provided for @receiptPhotos.
  ///
  /// In en, this message translates to:
  /// **'Receipt Photos'**
  String get receiptPhotos;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @photoCapturedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Photo captured successfully!'**
  String get photoCapturedSuccessfully;

  /// No description provided for @photoDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Photo deleted successfully!'**
  String get photoDeletedSuccessfully;

  /// No description provided for @failedToCapturePhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to capture photo'**
  String get failedToCapturePhoto;

  /// No description provided for @failedToDeletePhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete photo'**
  String get failedToDeletePhoto;

  /// No description provided for @fileSizeTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File size too large. Maximum size is 10MB.'**
  String get fileSizeTooLarge;

  /// No description provided for @unsupportedFileType.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file type. Please select a JPEG or PNG image.'**
  String get unsupportedFileType;

  /// No description provided for @noPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos attached'**
  String get noPhotos;

  /// No description provided for @photosAttached.
  ///
  /// In en, this message translates to:
  /// **'{count} photos attached'**
  String photosAttached(Object count);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
