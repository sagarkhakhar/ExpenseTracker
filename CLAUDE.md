# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Core Development
- `flutter run` - Run the app in debug mode
- `flutter run --release` - Run in release mode
- `flutter test` - Run all unit tests
- `flutter test --coverage` - Run tests with coverage report
- `flutter analyze` - Run static code analysis
- `dart format .` - Format all Dart code
- `flutter clean && flutter pub get` - Clean and reinstall dependencies

### Code Generation
- `dart run build_runner build` - Generate code (models, providers)
- `dart run build_runner build --delete-conflicting-outputs` - Regenerate with conflicts resolved
- `flutter gen-l10n` - Generate localization files

### Testing
- `flutter test test/features/expense/` - Run tests for specific feature
- `flutter test --plain-name "should create expense"` - Run specific test
- `flutter test integration_test/` - Run integration tests
- `timeout 30 flutter test test/features/statistics/domain/entities/financial_goal_test.dart --plain-name 'should'` - Run specific test with timeout

### Quality Assurance
- `./scripts/quality_check.sh` - Run comprehensive quality checks (linting, testing, security, performance)
- `flutter build apk --release` - Build release APK
- `flutter build web --release` - Build web version

### Supabase (Backend)
- `supabase start` - Start local Supabase instance
- `supabase functions serve` - Serve edge functions locally
- `supabase db reset` - Reset database to initial state
- `supabase secrets list` - List environment secrets

### Docker Supabase Management
- `./scripts/supabase-docker.sh start` - Start Supabase with Docker
- `./scripts/supabase-docker.sh stop` - Stop all Supabase services
- `./scripts/supabase-docker.sh status` - Check service status
- `./scripts/supabase-docker.sh info` - Show connection details
- `./scripts/supabase-docker.sh reset` - Reset database to stable state
- `./scripts/supabase-docker.sh setup` - Full setup from scratch

### Environment Management & Deployment
- `flutter run` - Run on local Docker Supabase (default)
- `flutter run --dart-define-from-file=.env.production` - Run on remote Supabase
- `./scripts/deploy_schema_updates.sh` - Deploy local schema to remote
- `./scripts/deploy_schema_updates.sh --dry-run` - Preview schema changes
- `supabase link --project-ref YOUR_ID` - Link to remote Supabase project
- `supabase db push --linked` - Push migrations to remote

## Architecture Overview

This is a production-grade Flutter expense tracker application built using **Clean Architecture** with **MVVM** pattern and **Riverpod** state management.

### Core Architecture Principles
- **Clean Architecture** - Clear separation between Domain, Data, and Presentation layers
- **Feature-based organization** - Each feature (expense, budget, statistics, export) is self-contained
- **Offline-first** - Uses Hive for local storage with optional Supabase sync
- **Type-safe state management** - Riverpod with code generation for providers
- **Comprehensive testing** - Unit, widget, and integration tests with high coverage

### Layer Structure

#### Domain Layer (`lib/features/*/domain/`)
- **Entities** - Core business objects (Expense, Budget, FinancialGoal, etc.)
- **Repositories** - Abstract interfaces defining data contracts
- **Use Cases** - Business logic operations (CreateExpense, GetBudgets, etc.)
- **Services** - Domain-specific services (FilterService, BudgetService)
- **Validators** - Business rule validation

#### Data Layer (`lib/features/*/data/`)
- **Models** - Data transfer objects with JSON serialization
- **DataSources** - Concrete data access (Hive local storage, Supabase remote)
- **Repositories** - Implementation of domain repository contracts
- **Mappers** - Convert between models and entities

#### Presentation Layer (`lib/features/*/presentation/`)
- **Views** - UI screens and widgets
- **Providers** - Riverpod state management with AsyncNotifier pattern
- **Widgets** - Reusable UI components

### Key Features Architecture

#### Expense Management
- Full CRUD operations with photo attachments
- Advanced filtering and search capabilities
- Category-based organization
- Receipt photo storage and management

#### Budget System
- Category-wise budget allocation
- Progress tracking with visual indicators
- Alert system for budget thresholds
- Historical budget performance

#### Statistics & Analytics
- Financial goal tracking
- Trend analysis with visual charts
- Category breakdown and insights
- Export functionality (CSV, JSON)

#### Sync System (Supabase Integration)
- Bidirectional data synchronization
- Conflict resolution with Last-Write-Wins strategy
- Offline operation with mutation queue
- Background sync orchestration

### State Management Pattern

Uses **Riverpod** with code generation:
- `@riverpod` annotation for provider generation
- `AsyncNotifier` for complex async state
- `AsyncValue` for loading/error/data states
- Family providers for parameterized state

Example provider pattern:
```dart
@riverpod
class ExpenseNotifier extends _$ExpenseNotifier {
  @override
  FutureOr<List<Expense>> build() async {
    return ref.read(getAllExpensesProvider).call();
  }
}
```

### Database Schema

#### Local Storage (Hive)
- **expenses.hive** - Core expense data
- **budgets.hive** - Budget configurations
- **goals.hive** - Financial goals
- **photos.hive** - Receipt photo metadata
- **sync_metadata.hive** - Synchronization tracking

#### Remote Storage (Supabase)
- **expenses** - Synchronized expense records
- **budgets** - Budget data with user isolation
- **categories** - Shared and user-specific categories
- **accounts** - User account information

### Testing Strategy

#### Test Organization
- Unit tests mirror the `lib/` structure in `test/`
- Feature tests are organized by layer (domain, data, presentation)
- Integration tests in `integration_test/` folder
- Test helpers and mocks in `test/helpers/`

#### Coverage Requirements
- Domain layer: 95%+ coverage (business logic is critical)
- Data layer: 90%+ coverage (data integrity)
- Presentation layer: 80%+ coverage (UI behavior)

#### Running Tests
```bash
flutter test                                    # All tests
flutter test test/features/expense/domain/      # Domain tests for expense feature
flutter test --coverage                         # With coverage report
```

### Code Generation

The project uses extensive code generation:
- **json_serializable** - Model serialization
- **hive_generator** - Hive type adapters
- **riverpod_generator** - Provider generation

Always run after model changes:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Localization

Supports English and Spanish with Flutter's l10n system:
- ARB files in `lib/l10n/`
- Generated classes in `lib/l10n/app_localizations.dart`
- Usage: `AppLocalizations.of(context)!.keyName`

Generate after ARB file changes:
```bash
flutter gen-l10n
```

### Security Considerations

- No hardcoded secrets (use Supabase environment variables)
- Local data encrypted with Hive encryption (when enabled)
- Input validation at domain and presentation layers
- File system access restricted to app documents directory

### Performance Optimizations

- **Lazy loading** - Data loaded on demand
- **Memory efficient** - Proper widget disposal and stream management
- **Optimized builds** - Const constructors and efficient rebuilds
- **Image optimization** - Compressed photo storage
- **Database indexing** - Efficient Hive queries

### Development Workflow

1. **Feature Development**
   - Start with domain entities and use cases
   - Implement data layer with tests
   - Build presentation layer with Riverpod providers
   - Add comprehensive tests for all layers

2. **Code Quality**
   - Run `flutter analyze` for static analysis
   - Ensure all tests pass with `flutter test`
   - Check formatting with `dart format`
   - Use quality script: `./scripts/quality_check.sh`

3. **Debugging**
   - Use Flutter Inspector for widget debugging
   - Riverpod DevTools for state inspection
   - Hive browser for local database inspection
   - Supabase dashboard for remote data

### Common Patterns

#### Error Handling
Uses `Either<Failure, Success>` pattern from `dartz`:
```dart
Either<Failure, List<Expense>> result = await repository.getExpenses();
result.fold(
  (failure) => handleError(failure),
  (expenses) => displayExpenses(expenses),
);
```

#### Async State Management
```dart
ref.watch(expenseProvider).when(
  data: (expenses) => ExpenseList(expenses: expenses),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => ErrorWidget(error.toString()),
);
```

#### Validation
Domain validators return `Either<String, T>`:
```dart
Either<String, double> validateAmount(String input) {
  final amount = double.tryParse(input);
  if (amount == null || amount <= 0) {
    return Left('Amount must be a positive number');
  }
  return Right(amount);
}
```

### Build and Deployment

#### Local Development
```bash
flutter run                    # Debug mode
flutter run --release          # Release mode
flutter run -d chrome          # Web version
```

#### Production Builds
```bash
flutter build apk --release    # Android APK
flutter build appbundle        # Android App Bundle (Play Store)
flutter build ios --release    # iOS
flutter build web --release    # Web deployment
```

### Environment Configuration

The app supports multiple environments through build-time configuration:
- Development (default)
- Staging  
- Production

Use `--dart-define` flags for environment-specific builds:
```bash
flutter build apk --release --dart-define=ENVIRONMENT=production --dart-define=SUPABASE_URL=your-url
```

### Troubleshooting

#### Common Issues
1. **Code generation failures** - Run `flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs`
2. **Hive type adapter errors** - Regenerate with build_runner after entity changes
3. **Riverpod provider issues** - Check provider dependencies and async patterns
4. **Test failures** - Verify mock setup and async test patterns

#### Performance Issues
- Use Flutter Inspector to identify expensive rebuilds
- Check for memory leaks with provider disposal
- Profile with `flutter run --profile`
- Optimize images and reduce widget nesting