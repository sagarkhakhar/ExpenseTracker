// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Expense Tracker';

  @override
  String get overview => 'Overview';

  @override
  String get stats => 'Statistics';

  @override
  String get addExpense => 'Add Expense';

  @override
  String get editExpense => 'Edit Expense';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get title => 'Title';

  @override
  String get description => 'Description';

  @override
  String get amount => 'Amount';

  @override
  String get category => 'Category';

  @override
  String get type => 'Type';

  @override
  String get date => 'Date';

  @override
  String get recurring => 'Recurring';

  @override
  String get frequency => 'Frequency';

  @override
  String get nextOccurrence => 'Next Occurrence';

  @override
  String get endDate => 'End Date (optional)';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get noExpenses => 'No expenses yet';

  @override
  String get addFirstExpense => 'Add your first expense to get started';

  @override
  String get deleteExpense => 'Delete Expense';

  @override
  String get deleteExpenseConfirm => 'Are you sure you want to delete this expense?';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Close';

  @override
  String get manageCategories => 'Manage Categories';

  @override
  String get addCategory => 'Add new category';

  @override
  String get duplicateCategory => 'Duplicate category name.';

  @override
  String get categoryInUse => 'Cannot delete: Category is in use.';

  @override
  String get categoryNameEmpty => 'Category name cannot be empty.';

  @override
  String get enterTitle => 'Enter a title';

  @override
  String get enterAmount => 'Enter a valid amount';

  @override
  String get selectCategory => 'Please select a valid category.';

  @override
  String get invalidAmount => 'Enter a valid, positive amount (max \$1,000,000).';

  @override
  String get incomeNegative => 'Income cannot be negative.';

  @override
  String get selectFrequency => 'Select a recurring frequency.';

  @override
  String get selectNextOccurrence => 'Select next occurrence date.';

  @override
  String get nextOccurrenceAfterDate => 'Next occurrence must be after or equal to the main date.';

  @override
  String get endDateAfterNext => 'End date must be after next occurrence.';

  @override
  String get invalidData => 'Invalid data. Please check all fields.';

  @override
  String failedAdd(Object error) {
    return 'Failed to add expense: $error';
  }

  @override
  String failedEdit(Object error) {
    return 'Failed to edit expense: $error';
  }

  @override
  String get retry => 'Retry';

  @override
  String get errorLoadingExpenses => 'Error loading expenses';

  @override
  String get smartTips => 'Smart Tips';

  @override
  String get noData => 'No data to display';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get custom => 'Custom';

  @override
  String get dailyTrend => 'Daily Cash Flow Trend';

  @override
  String get expensesByCategory => 'Expenses by Category';

  @override
  String get incomeByCategory => 'Income by Category';

  @override
  String get tipHighSpending => 'You\'re spending over 80% of your income. Consider saving more this month.';

  @override
  String get tipNoIncome => 'No income recorded this month. Add your income to track your balance.';

  @override
  String tipCategorySpike(Object category) {
    return 'High spending on \'$category\'. Consider reviewing this category.';
  }

  @override
  String get tipNegativeBalance => 'Your balance is negative. Try to reduce expenses or increase income.';

  @override
  String get tipFewExpenses => 'Add more expenses to get better insights and tips.';

  @override
  String get tipAllGood => 'Great job! Your spending is under control this month.';

  @override
  String get receiptPhotos => 'Receipt Photos';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get photoCapturedSuccessfully => 'Photo captured successfully!';

  @override
  String get photoDeletedSuccessfully => 'Photo deleted successfully!';

  @override
  String get failedToCapturePhoto => 'Failed to capture photo';

  @override
  String get failedToDeletePhoto => 'Failed to delete photo';

  @override
  String get fileSizeTooLarge => 'File size too large. Maximum size is 10MB.';

  @override
  String get unsupportedFileType => 'Unsupported file type. Please select a JPEG or PNG image.';

  @override
  String get noPhotos => 'No photos attached';

  @override
  String photosAttached(Object count) {
    return '$count photos attached';
  }

  @override
  String get preview => 'Preview';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get addGoal => 'Add Goal';

  @override
  String get viewDetails => 'View Details';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String get clearAll => 'Clear All';

  @override
  String get refresh => 'Refresh';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get copyPath => 'Copy Path';

  @override
  String get copyAll => 'Copy All';

  @override
  String get share => 'Share';

  @override
  String get openFile => 'Open File';

  @override
  String get add => 'Add';

  @override
  String get deleteBudget => 'Delete Budget';

  @override
  String get deletePhoto => 'Delete Photo';

  @override
  String get addFinancialGoal => 'Add Financial Goal';

  @override
  String get exportData => 'Export Data';

  @override
  String get permissionRequired => 'Permission Required';

  @override
  String get fileOpeningFailed => 'File Opening Failed';

  @override
  String fileContents(String fileName) {
    return 'File Contents: $fileName';
  }

  @override
  String deleteBudgetConfirm(String categoryId) {
    return 'Are you sure you want to delete the budget for \"$categoryId\"?';
  }

  @override
  String get deletePhotoConfirm => 'Are you sure you want to delete this photo?';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get titleTooLong => 'Title cannot exceed 100 characters';

  @override
  String get amountMustBePositive => 'Amount must be positive';

  @override
  String get amountTooLarge => 'Amount cannot exceed \$1,000,000';

  @override
  String get categoryRequired => 'Category is required';

  @override
  String get categoryTooLong => 'Category cannot exceed 50 characters';

  @override
  String get dateRequired => 'Date is required';

  @override
  String get dateOutOfRange => 'Date must be within one year of today';

  @override
  String errorSharingFile(String error) {
    return 'Error sharing file: $error';
  }

  @override
  String get fileDoesNotExist => 'File does not exist';

  @override
  String get fileAppearsEmpty => 'File appears to be empty';

  @override
  String couldNotOpenFile(String filePath) {
    return 'Could not open file. File is saved at: $filePath';
  }

  @override
  String get filePathCopied => 'File path copied to clipboard!';

  @override
  String get viewContents => 'View Contents';

  @override
  String errorOpeningFile(String error) {
    return 'Error opening file: $error';
  }

  @override
  String errorReadingFile(String error) {
    return 'Error reading file: $error';
  }

  @override
  String get fileContentsCopied => 'File contents copied to clipboard!';

  @override
  String get noCategoryData => 'No category data available';

  @override
  String get invalidCategoryData => 'Invalid category data';

  @override
  String get errorRenderingChart => 'Error rendering chart';

  @override
  String get noTrendData => 'No trend data available';

  @override
  String get chartAreaTooSmall => 'Chart area too small';

  @override
  String get chartNeedsDimensions => 'Chart needs defined dimensions';

  @override
  String get insufficientDataForChart => 'Insufficient data for chart';

  @override
  String get noSpendingData => 'No spending data to display';

  @override
  String expenseDeletedSuccessfully(String title) {
    return 'Expense \"$title\" deleted successfully';
  }

  @override
  String failedToDeleteExpense(String error) {
    return 'Failed to delete expense: $error';
  }

  @override
  String goalCreatedSuccessfully(String title) {
    return 'Goal \"$title\" created successfully!';
  }

  @override
  String get pleaseEnterGoalTitle => 'Please enter a goal title';

  @override
  String get pleaseEnterValidAmount => 'Please enter a valid target amount';

  @override
  String get pleaseSelectTargetDate => 'Please select a target date';

  @override
  String get targetDate => 'Target Date';

  @override
  String categoryLabel(String category) {
    return 'Category: $category';
  }

  @override
  String typeLabel(String type) {
    return 'Type: $type';
  }

  @override
  String searchLabel(String searchText) {
    return 'Search: \"$searchText\"';
  }

  @override
  String get addBudget => 'Add Budget';

  @override
  String errorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String errorLoadingBudgets(String error) {
    return 'Error loading budgets: $error';
  }

  @override
  String errorLoadingTips(String error) {
    return 'Error loading tips: $error';
  }

  @override
  String errorLoadingEnhancedStats(String error) {
    return 'Error loading enhanced statistics: $error';
  }

  @override
  String get noExpensesToExport => 'No expenses to export';

  @override
  String get exportFileNotFound => 'Export file not found. Please try exporting again.';

  @override
  String fileNotFoundAt(String filePath) {
    return 'File not found at: $filePath';
  }

  @override
  String get enhancedStatistics => 'Enhanced Statistics';

  @override
  String get filterExpenses => 'Filter Expenses';

  @override
  String dateFormat(String day, String month) {
    return '$day/$month';
  }
}
