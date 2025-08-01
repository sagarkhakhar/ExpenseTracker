# Source Tree Integration

## Existing Project Structure

```
expense_tracker/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart
│   │   ├── errors/
│   │   │   └── failures.dart
│   │   └── utils/
│   │       ├── currency_utils.dart
│   │       └── date_utils.dart
│   ├── features/
│   │   └── expense/
│   │       ├── data/
│   │       │   ├── datasources/
│   │       │   │   ├── expense_local_data_source.dart
│   │       │   │   └── expense_local_data_source_impl.dart
│   │       │   ├── models/
│   │       │   │   └── expense_model.dart
│   │       │   └── repositories/
│   │       │       └── expense_repository_impl.dart
│   │       ├── domain/
│   │       │   ├── entities/
│   │       │   │   └── expense.dart
│   │       │   ├── repositories/
│   │       │   │   └── expense_repository.dart
│   │       │   └── usecases/
│   │       │       ├── create_expense.dart
│   │       │       ├── get_all_expenses.dart
│   │       │       ├── get_expenses_by_date_range.dart
│   │       │       └── update_expense.dart
│   │       └── presentation/
│   │           ├── providers/
│   │           │   └── expense_providers.dart
│   │           ├── views/
│   │           │   ├── add_expense_screen.dart
│   │           │   ├── home_screen.dart
│   │           │   └── stats_screen.dart
│   │           └── widgets/
│   │               ├── add_expense_fab.dart
│   │               ├── expense_list.dart
│   │               ├── expense_pie_chart.dart
│   │               └── expense_summary_card.dart
│   ├── l10n/
│   │   ├── app_en.arb
│   │   ├── app_es.arb
│   │   ├── app_localizations.dart
│   │   ├── app_localizations_en.dart
│   │   └── app_localizations_es.dart
│   ├── shared/
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   └── widgets/
│   │       └── platform_widgets.dart
│   └── main.dart
├── test/
│   ├── core/
│   │   └── utils/
│   │       └── currency_utils_test.dart
│   ├── features/
│   │   └── expense/
│   │       ├── domain/
│   │       │   └── usecases/
│   │       │       ├── create_expense_test.dart
│   │       │       └── update_expense_test.dart
│   │       └── presentation/
│   │           └── views/
│   │               ├── add_expense_screen_test.dart
│   │               └── category_manager_dialog_test.dart
│   └── widget_test.dart
└── pubspec.yaml
```

## New File Organization

```
expense_tracker/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart          # Existing file
│   │   ├── errors/
│   │   │   └── failures.dart              # Existing file
│   │   └── utils/
│   │       ├── currency_utils.dart        # Existing file
│   │       ├── date_utils.dart            # Existing file
│   │       ├── export_utils.dart          # NEW: CSV/JSON export utilities
│   │       └── photo_utils.dart           # NEW: Photo processing utilities
│   ├── features/
│   │   ├── expense/                       # Existing feature
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── expense_local_data_source.dart
│   │   │   │   │   └── expense_local_data_source_impl.dart
│   │   │   │   ├── models/
│   │   │   │   │   ├── expense_model.dart
│   │   │   │   │   └── expense_model.dart # Modified: Add photo reference
│   │   │   │   └── repositories/
│   │   │   │       └── expense_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── expense.dart       # Modified: Add photo metadata
│   │   │   │   ├── repositories/
│   │   │   │   │   └── expense_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── create_expense.dart
│   │   │   │       ├── get_all_expenses.dart
│   │   │   │       ├── get_expenses_by_date_range.dart
│   │   │   │       ├── update_expense.dart
│   │   │   │       └── search_expenses.dart # NEW: Search functionality
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   ├── expense_providers.dart
│   │   │       │   └── filter_providers.dart # NEW: Filter state management
│   │   │       ├── views/
│   │   │       │   ├── add_expense_screen.dart # Modified: Add photo capture
│   │   │       │   ├── home_screen.dart
│   │   │       │   └── stats_screen.dart   # Modified: Add budget tracking
│   │   │       └── widgets/
│   │   │           ├── add_expense_fab.dart
│   │   │           ├── expense_list.dart   # Modified: Add filtering
│   │   │           ├── expense_pie_chart.dart
│   │   │           ├── expense_summary_card.dart
│   │   │           ├── budget_indicator.dart # NEW: Budget progress indicator
│   │   │           ├── filter_widget.dart   # NEW: Advanced filtering UI
│   │   │           └── receipt_photo_widget.dart # NEW: Photo display
│   │   ├── budget/                        # NEW: Budget management feature
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── budget_local_data_source.dart
│   │   │   │   ├── models/
│   │   │   │   │   └── budget_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── budget_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── budget.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── budget_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── create_budget.dart
│   │   │   │       ├── get_budgets.dart
│   │   │   │       └── update_budget.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── budget_providers.dart
│   │   │       ├── views/
│   │   │       │   └── budget_management_screen.dart
│   │   │       └── widgets/
│   │   │           ├── budget_card.dart
│   │   │           └── budget_progress_bar.dart
│   │   ├── receipt_photos/                # NEW: Receipt photo feature
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── photo_local_data_source.dart
│   │   │   │   ├── models/
│   │   │   │   │   └── receipt_photo_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── photo_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── receipt_photo.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── photo_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── capture_photo.dart
│   │   │   │       ├── save_photo.dart
│   │   │   │       └── get_photos.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── photo_providers.dart
│   │   │       ├── views/
│   │   │       │   └── photo_capture_screen.dart
│   │   │       └── widgets/
│   │   │           ├── photo_capture_widget.dart
│   │   │           └── photo_gallery_widget.dart
│   │   ├── export/                        # NEW: Data export feature
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── export_local_data_source.dart
│   │   │   │   ├── models/
│   │   │   │   │   └── export_history_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── export_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── export_history.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── export_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── export_to_csv.dart
│   │   │   │       ├── export_to_json.dart
│   │   │   │       └── get_export_history.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── export_providers.dart
│   │   │       ├── views/
│   │   │       │   └── export_screen.dart
│   │   │       └── widgets/
│   │   │           ├── export_format_selector.dart
│   │   │           └── export_history_list.dart
│   │   └── settings/                      # NEW: Settings management feature
│   │       ├── data/
│   │       │   ├── datasources/
│   │       │   │   └── settings_local_data_source.dart
│   │       │   ├── models/
│   │       │   │   └── user_settings_model.dart
│   │       │   └── repositories/
│   │       │       └── settings_repository_impl.dart
│   │       ├── domain/
│   │       │   ├── entities/
│   │       │   │   └── user_settings.dart
│   │       │   ├── repositories/
│   │       │   │   └── settings_repository.dart
│   │       │   └── usecases/
│   │       │       ├── get_settings.dart
│   │       │       └── update_settings.dart
│   │       └── presentation/
│   │           ├── providers/
│   │           │   └── settings_providers.dart
│   │           ├── views/
│   │           │   └── settings_screen.dart
│   │           └── widgets/
│   │               ├── currency_selector.dart
│   │               ├── category_selector.dart
│   │               └── notification_settings.dart
│   ├── l10n/                              # Existing localization
│   │   ├── app_en.arb                     # Modified: Add new strings
│   │   ├── app_es.arb                     # Modified: Add new strings
│   │   ├── app_localizations.dart
│   │   ├── app_localizations_en.dart
│   │   └── app_localizations_es.dart
│   ├── shared/                            # Existing shared components
│   │   ├── theme/
│   │   │   └── app_theme.dart             # Modified: Add new theme constants
│   │   └── widgets/
│   │       └── platform_widgets.dart      # Modified: Add new platform widgets
│   └── main.dart                          # Modified: Initialize new features
├── test/                                  # Existing test structure
│   ├── core/
│   │   └── utils/
│   │       ├── currency_utils_test.dart
│   │       ├── export_utils_test.dart     # NEW: Export utilities tests
│   │       └── photo_utils_test.dart      # NEW: Photo utilities tests
│   ├── features/
│   │   ├── expense/                       # Existing expense tests
│   │   │   ├── domain/
│   │   │   │   └── usecases/
│   │   │   │       ├── create_expense_test.dart
│   │   │   │       ├── update_expense_test.dart
│   │   │   │       └── search_expenses_test.dart # NEW: Search tests
│   │   │   └── presentation/
│   │   │       └── views/
│   │   │           ├── add_expense_screen_test.dart
│   │   │           └── category_manager_dialog_test.dart
│   │   ├── budget/                        # NEW: Budget feature tests
│   │   │   ├── domain/
│   │   │   │   └── usecases/
│   │   │   │       ├── create_budget_test.dart
│   │   │   │       └── get_budgets_test.dart
│   │   │   └── presentation/
│   │   │       └── views/
│   │   │           └── budget_management_screen_test.dart
│   │   ├── receipt_photos/                # NEW: Photo feature tests
│   │   │   ├── domain/
│   │   │   │   └── usecases/
│   │   │   │       ├── capture_photo_test.dart
│   │   │   │       └── save_photo_test.dart
│   │   │   └── presentation/
│   │   │       └── views/
│   │   │           └── photo_capture_screen_test.dart
│   │   ├── export/                        # NEW: Export feature tests
│   │   │   ├── domain/
│   │   │   │   └── usecases/
│   │   │   │       ├── export_to_csv_test.dart
│   │   │   │       └── export_to_json_test.dart
│   │   │   └── presentation/
│   │   │       └── views/
│   │   │           └── export_screen_test.dart
│   │   └── settings/                      # NEW: Settings feature tests
│   │       ├── domain/
│   │       │   └── usecases/
│   │       │       ├── get_settings_test.dart
│   │       │       └── update_settings_test.dart
│   │       └── presentation/
│   │           └── views/
│   │               └── settings_screen_test.dart
│   └── widget_test.dart
└── pubspec.yaml                           # Modified: Add new dependencies
```

## Integration Guidelines

- **File Naming:** Follow existing snake_case pattern for all new files
- **Folder Organization:** Maintain Clean Architecture structure with Domain-Data-Presentation layers
- **Import/Export Patterns:** Use relative imports following existing patterns
- **Code Organization:** Each new feature follows the same structure as existing expense feature
- **Testing Structure:** Mirror existing test organization for new features
- **Localization:** Add new strings to existing ARB files
- **Shared Components:** Extend existing shared utilities and widgets
