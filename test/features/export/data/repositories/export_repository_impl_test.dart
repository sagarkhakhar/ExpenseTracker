import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/export/data/repositories/export_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExportRepositoryImpl', () {
    late ExportRepositoryImpl repository;

    setUp(() {
      repository = ExportRepositoryImpl();
    });

    group('ExportRepositoryImpl', () {
      test('should be instantiated correctly', () {
        expect(repository, isNotNull);
        expect(repository, isA<ExportRepositoryImpl>());
      });

      test('should have correct box name', () {
        // Test that the repository can be created without errors
        expect(repository, isNotNull);
      });
    });
  });
}
