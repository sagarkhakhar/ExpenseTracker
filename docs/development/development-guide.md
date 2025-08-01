# Development Guide

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (latest stable version)
- Android Studio / VS Code
- Git

### Setup Instructions

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter doctor` to verify setup
4. Run `flutter test` to verify everything works

## Project Structure

```
lib/
├── core/                    # Core utilities and constants
│   ├── constants/          # App constants
│   ├── errors/             # Error handling
│   └── utils/              # Utility functions
├── features/               # Feature modules
│   ├── expense/            # Expense management
│   │   ├── data/          # Data layer
│   │   ├── domain/        # Domain layer
│   │   └── presentation/  # Presentation layer
│   ├── budget/            # Budget management
│   └── photo/             # Photo system
├── shared/                 # Shared components
│   ├── theme/             # App theming
│   └── widgets/           # Shared widgets
└── l10n/                  # Localization
```

## Architecture Guidelines

### Clean Architecture Principles

- **Dependency Rule**: Dependencies point inward
- **Domain Layer**: Pure business logic, no dependencies
- **Data Layer**: Implements domain interfaces
- **Presentation Layer**: UI and state management

### Code Organization

- **Feature-based**: Organize by feature, not by layer
- **Single Responsibility**: Each class has one reason to change
- **Dependency Injection**: Use Riverpod for dependency management
- **Error Handling**: Use Either types for error handling

## Development Workflow

### 1. Feature Development

1. **Create Domain Layer**

   - Define entities
   - Create repository interfaces
   - Implement use cases
   - Add unit tests

2. **Implement Data Layer**

   - Create data models
   - Implement repositories
   - Add data sources
   - Add unit tests

3. **Build Presentation Layer**
   - Create UI components
   - Implement state management
   - Add navigation
   - Add widget tests

### 2. Testing Strategy

- **Unit Tests**: Test business logic and data operations
- **Widget Tests**: Test UI components
- **Integration Tests**: Test complete workflows
- **Test Coverage**: Aim for 80%+ coverage

### 3. Code Quality

- **Linting**: Follow Dart/Flutter linting rules
- **Formatting**: Use `dart format` for consistent formatting
- **Documentation**: Document public APIs
- **Code Review**: Review all changes

## State Management

### Riverpod Best Practices

```dart
// Good: Use StateNotifier for complex state
class ExpenseNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  ExpenseNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    state = const AsyncValue.loading();
    final result = await _repository.getAllExpenses();
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (expenses) => AsyncValue.data(expenses),
    );
  }
}

// Good: Use FutureProvider for simple async data
final expenseProvider = FutureProvider<List<Expense>>((ref) async {
  final repository = ref.read(expenseRepositoryProvider);
  final result = await repository.getAllExpenses();
  return result.fold(
    (failure) => throw failure,
    (expenses) => expenses,
  );
});
```

### State Management Patterns

- **Loading States**: Use AsyncValue for loading/error/success states
- **Error Handling**: Proper error propagation and display
- **Optimistic Updates**: Update UI immediately, sync with backend
- **Caching**: Cache frequently accessed data

## Database Operations

### Hive Best Practices

```dart
// Good: Proper box initialization
class ExpenseLocalDataSourceImpl implements ExpenseLocalDataSource {
  late Box<ExpenseModel> _box;

  Future<void> init() async {
    if (!Hive.isBoxOpen('expenses')) {
      _box = await Hive.openBox<ExpenseModel>('expenses');
    } else {
      _box = Hive.box<ExpenseModel>('expenses');
    }
  }
}

// Good: Efficient batch operations
Future<void> seedDummyData() async {
  final expenses = generateDummyExpenses();
  await _box.addAll(expenses.map((e) => e.toModel()));
}
```

### Database Guidelines

- **Transactions**: Use transactions for multiple operations
- **Indexing**: Index frequently queried fields
- **Batch Operations**: Use batch operations for bulk data
- **Error Handling**: Handle database errors gracefully

## UI Development

### Platform-Specific UI

```dart
// Good: Platform-aware widgets
class PlatformWidgets {
  static Widget buildAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
  }) {
    if (PlatformWidgets.isIOS) {
      return CupertinoNavigationBar(
        middle: Text(title),
        trailing: actions != null ? Row(mainAxisSize: MainAxisSize.min, children: actions) : null,
      );
    } else {
      return AppBar(
        title: Text(title),
        actions: actions,
      );
    }
  }
}
```

### UI Guidelines

- **Responsive Design**: Support different screen sizes
- **Accessibility**: Include semantic labels and descriptions
- **Performance**: Optimize widget rebuilds
- **Consistency**: Follow design system guidelines

## Error Handling

### Error Types

```dart
// Good: Specific error types
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(String message) : super(message);
}
```

### Error Handling Patterns

- **Either Types**: Use Either<Failure, Success> for operations that can fail
- **Error Propagation**: Propagate errors up the call stack
- **User-Friendly Messages**: Show user-friendly error messages
- **Error Recovery**: Provide recovery options when possible

## Testing

### Unit Testing

```dart
// Good: Comprehensive unit tests
group('CreateExpense', () {
  late MockExpenseRepository mockRepository;
  late CreateExpense useCase;

  setUp(() {
    mockRepository = MockExpenseRepository();
    useCase = CreateExpense(mockRepository);
  });

  test('should return success when expense is valid', () async {
    // Arrange
    final expense = validExpense;
    when(() => mockRepository.createExpense(expense))
        .thenAnswer((_) async => Right(expense));

    // Act
    final result = await useCase(expense);

    // Assert
    expect(result, Right(expense));
    verify(() => mockRepository.createExpense(expense)).called(1);
  });
});
```

### Widget Testing

```dart
// Good: Widget testing with proper setup
testWidgets('should display expense list', (WidgetTester tester) async {
  // Arrange
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseProvider.overrideWith((ref) => mockExpenses),
      ],
      child: const MaterialApp(
        home: ExpenseList(),
      ),
    ),
  );

  // Act
  await tester.pumpAndSettle();

  // Assert
  expect(find.byType(ExpenseCard), findsNWidgets(mockExpenses.length));
});
```

## Performance Optimization

### Widget Optimization

- **const Constructors**: Use const constructors where possible
- **RepaintBoundary**: Wrap expensive widgets
- **ListView.builder**: Use for large lists
- **Image Caching**: Cache images efficiently

### Database Optimization

- **Indexed Queries**: Index frequently queried fields
- **Batch Operations**: Use batch operations for bulk data
- **Lazy Loading**: Load data on demand
- **Query Optimization**: Optimize complex queries

## Code Style

### Naming Conventions

- **Classes**: PascalCase (e.g., `ExpenseModel`)
- **Variables**: camelCase (e.g., `expenseList`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `MAX_FILE_SIZE`)
- **Files**: snake_case (e.g., `expense_model.dart`)

### Documentation

````dart
/// Creates a new expense with the given details.
///
/// This use case validates the expense data and persists it to the repository.
/// Returns a [Failure] if validation fails or the operation cannot be completed.
///
/// Example:
/// ```dart
/// final result = await createExpense(expense);
/// result.fold(
///   (failure) => print('Error: ${failure.message}'),
///   (expense) => print('Created: ${expense.title}'),
/// );
/// ```
class CreateExpense {
  final ExpenseRepository _repository;

  const CreateExpense(this._repository);

  Future<Either<Failure, Expense>> call(Expense expense) async {
    // Implementation
  }
}
````

## Deployment

### Build Configuration

- **Debug**: Development with hot reload
- **Release**: Optimized production build
- **Profile**: Performance profiling
- **Test**: Automated testing

### Platform-Specific Configuration

- **Android**: Configure signing and permissions
- **iOS**: Configure certificates and capabilities
- **Web**: Configure PWA settings
- **Desktop**: Configure platform-specific settings

## Troubleshooting

### Common Issues

1. **Hive Errors**: Ensure proper initialization and adapter registration
2. **State Management**: Check provider dependencies and state updates
3. **Performance**: Monitor widget rebuilds and database queries
4. **Testing**: Ensure proper test setup and mocking

### Debug Tools

- **Flutter Inspector**: Debug widget tree
- **Performance Overlay**: Monitor frame rate
- **Debug Console**: View logs and errors
- **Network Inspector**: Monitor network requests

## Contributing

### Pull Request Process

1. Create feature branch
2. Implement changes with tests
3. Update documentation
4. Run all tests
5. Submit pull request
6. Code review and approval
7. Merge to main branch

### Code Review Checklist

- [ ] Code follows style guidelines
- [ ] Tests are included and passing
- [ ] Documentation is updated
- [ ] No breaking changes
- [ ] Performance impact considered
- [ ] Security implications reviewed
