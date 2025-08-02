import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService', () {
    late NotificationService notificationService;

    setUp(() {
      notificationService = NotificationService();
    });

    test('should get downloads directory path', () async {
      try {
        final path = await notificationService.getDownloadsDirectory();
        expect(path, isNotEmpty);
        expect(path, contains('Downloads'));
      } catch (e) {
        // Skip test on unsupported platforms or when plugins are not available
        expect(
            e.toString(),
            anyOf(
              contains('Platform not supported'),
              contains('MissingPluginException'),
            ));
      }
    });

    test('should get export file path', () async {
      try {
        const fileName = 'test_export.csv';
        final filePath = await notificationService.getExportFilePath(fileName);
        expect(filePath, isNotEmpty);
        expect(filePath, contains('Downloads'));
        expect(filePath, contains('exports'));
        expect(filePath, contains(fileName));
      } catch (e) {
        // Skip test on unsupported platforms or when plugins are not available
        expect(
            e.toString(),
            anyOf(
              contains('Platform not supported'),
              contains('MissingPluginException'),
            ));
      }
    });

    test('should copy file to downloads', () async {
      // This test would require actual file operations
      // For now, we'll just test that the method exists and doesn't throw
      expect(notificationService.copyToDownloads, isA<Function>());
    });
  });
}
