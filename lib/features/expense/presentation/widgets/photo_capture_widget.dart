// This file defines the PhotoCaptureWidget for capturing photos from camera or gallery.
// It provides a user interface for photo capture operations.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../../../l10n/app_localizations.dart';
import '../providers/photo_providers.dart';

/// Widget for capturing photos from camera or gallery.
/// Provides buttons to select camera or gallery and handles the capture process.
class PhotoCaptureWidget extends ConsumerWidget {
  final String expenseId;
  final VoidCallback? onPhotoCaptured;
  final VoidCallback? onError;

  const PhotoCaptureWidget({
    super.key,
    required this.expenseId,
    this.onPhotoCaptured,
    this.onError,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoCaptureState = ref.watch(photoCaptureNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            AppLocalizations.of(context)?.receiptPhotos ?? 'Receipt Photos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),

        // Capture buttons
        Row(
          children: [
            // Camera button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: photoCaptureState.isLoading
                    ? null
                    : () => _captureFromCamera(context, ref),
                icon: const Icon(Icons.camera_alt),
                label: Text(
                  AppLocalizations.of(context)?.camera ?? 'Camera',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Gallery button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: photoCaptureState.isLoading
                    ? null
                    : () => _captureFromGallery(context, ref),
                icon: const Icon(Icons.photo_library),
                label: Text(
                  AppLocalizations.of(context)?.gallery ?? 'Gallery',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),

        // Loading indicator
        if (photoCaptureState.isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),

        // Error message
        if (photoCaptureState.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Error: ${photoCaptureState.error}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),

        // Success message
        if (photoCaptureState.value?.isRight() == true)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              AppLocalizations.of(context)?.photoCapturedSuccessfully ??
                  'Photo captured successfully!',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  /// Capture photo from camera
  Future<void> _captureFromCamera(BuildContext context, WidgetRef ref) async {
    try {
      // Check camera permission
      final cameraStatus = await Permission.camera.status;
      if (cameraStatus.isDenied) {
        final result = await Permission.camera.request();
        if (result.isDenied || result.isPermanentlyDenied) {
          _showPermissionError(
              context, 'Camera permission is required to take photos');
          return;
        }
      }

      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _processCapturedImage(context, ref, image);
      }
    } catch (e) {
      _showError(context, 'Failed to capture from camera: $e');
    }
  }

  /// Capture photo from gallery
  Future<void> _captureFromGallery(BuildContext context, WidgetRef ref) async {
    try {
      // Check storage permission (for Android)
      if (Platform.isAndroid) {
        final storageStatus = await Permission.storage.status;
        if (storageStatus.isDenied) {
          final result = await Permission.storage.request();
          if (result.isDenied || result.isPermanentlyDenied) {
            _showPermissionError(
                context, 'Storage permission is required to access photos');
            return;
          }
        }
      }

      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _processCapturedImage(context, ref, image);
      }
    } catch (e) {
      _showError(context, 'Failed to capture from gallery: $e');
    }
  }

  /// Process the captured image
  Future<void> _processCapturedImage(
      BuildContext context, WidgetRef ref, XFile image) async {
    try {
      final file = File(image.path);
      final fileSize = await file.length();
      final fileName = image.name;
      final mimeType = _getMimeType(fileName);

      // Validate file size (10MB limit)
      if (fileSize > 10 * 1024 * 1024) {
        _showError(context, 'File size too large. Maximum size is 10MB.');
        return;
      }

      // Validate MIME type
      if (!_isValidMimeType(mimeType)) {
        _showError(context,
            'Unsupported file type. Please select a JPEG or PNG image.');
        return;
      }

      // Capture the photo using the use case
      final notifier = ref.read(photoCaptureNotifierProvider.notifier);
      await notifier.capturePhoto(
        expenseId: expenseId,
        filePath: image.path,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType,
        capturedAt: DateTime.now(),
      );

      // Check the result
      final state = ref.read(photoCaptureNotifierProvider);
      state.whenData((result) {
        result?.fold(
          (failure) {
            _showError(context, failure.message);
            onError?.call();
          },
          (receiptPhoto) {
            onPhotoCaptured?.call();
            // Reset the state after successful capture
            Future.delayed(const Duration(seconds: 2), () {
              notifier.reset();
            });
          },
        );
      });
    } catch (e) {
      _showError(context, 'Failed to process image: $e');
    }
  }

  /// Get MIME type from file name
  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      default:
        return 'image/jpeg';
    }
  }

  /// Check if MIME type is valid
  bool _isValidMimeType(String mimeType) {
    final validTypes = [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/heic',
      'image/heif',
    ];
    return validTypes.contains(mimeType.toLowerCase());
  }

  /// Show error message
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
    onError?.call();
  }

  /// Show permission error message with settings option
  void _showPermissionError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    onError?.call();
  }
}
