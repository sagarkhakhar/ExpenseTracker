// This file defines the PhotoCaptureWidget for capturing photos from camera or gallery.
// It provides a user interface for photo capture operations with preview functionality.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../../../l10n/app_localizations.dart';
import '../providers/photo_providers.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Widget for capturing photos from camera or gallery with preview functionality.
/// Provides buttons to select camera or gallery, shows preview, and handles the capture process.
class PhotoCaptureWidget extends ConsumerStatefulWidget {
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
  ConsumerState<PhotoCaptureWidget> createState() => _PhotoCaptureWidgetState();
}

class _PhotoCaptureWidgetState extends ConsumerState<PhotoCaptureWidget> {
  XFile? _previewImage;
  bool _isPreviewMode = false;

  @override
  Widget build(BuildContext context) {
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

        // Preview section
        if (_isPreviewMode && _previewImage != null) ...[
          _buildPreviewSection(context),
          const SizedBox(height: 16),
        ],

        // Capture buttons
        if (!_isPreviewMode) ...[
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
        ],

        // Loading indicator
        if (photoCaptureState.isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),

        // Error message - only show for actual photo capture errors, not permission issues
        if (photoCaptureState.hasError &&
            !photoCaptureState.error.toString().contains('permission') &&
            !photoCaptureState.error.toString().contains('Permission'))
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

  /// Build preview section
  Widget _buildPreviewSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview header
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Icon(
                  Icons.preview,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context)?.preview ?? 'Preview',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    _previewImage?.name ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),

          // Preview image
          Container(
            height: 120,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                File(_previewImage!.path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: Icon(
                      Icons.broken_image,
                      color: Theme.of(context).colorScheme.outline,
                      size: 32,
                    ),
                  );
                },
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // Save button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _savePreviewImage(context),
                    icon: const Icon(Icons.save, size: 16),
                    label: Text(
                      AppLocalizations.of(context)?.save ?? 'Save',
                      style: const TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Cancel button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelPreview(),
                    icon: const Icon(Icons.close, size: 16),
                    label: Text(
                      AppLocalizations.of(context)?.cancel ?? 'Cancel',
                      style: const TextStyle(fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Save the preview image
  Future<void> _savePreviewImage(BuildContext context) async {
    if (_previewImage == null) return;

    try {
      final file = File(_previewImage!.path);

      // Check if file exists
      if (!await file.exists()) {
        _showError(context, 'Selected image file does not exist.');
        return;
      }

      final fileSize = await file.length();
      final fileName = _previewImage!.name;
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
        expenseId: widget.expenseId,
        filePath: _previewImage!.path,
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
            widget.onError?.call();
          },
          (receiptPhoto) {
            widget.onPhotoCaptured?.call();
            _cancelPreview(); // Exit preview mode
            // Reset the state after successful capture
            Future.delayed(const Duration(seconds: 2), () {
              notifier.reset();
            });
          },
        );
      });
    } catch (e) {
      _showError(context, 'Failed to save image: $e');
    }
  }

  /// Cancel preview and return to capture mode
  void _cancelPreview() {
    setState(() {
      _previewImage = null;
      _isPreviewMode = false;
    });
  }

  /// Set preview image
  void _setPreviewImage(XFile image) {
    setState(() {
      _previewImage = image;
      _isPreviewMode = true;
    });
  }

  /// Capture photo from camera
  Future<void> _captureFromCamera(BuildContext context, WidgetRef ref) async {
    debugPrint('Camera button pressed - starting capture process');

    try {
      // Reset any previous error state
      ref.read(photoCaptureNotifierProvider.notifier).reset();

      // Check camera permission first
      final cameraStatus = await Permission.camera.status;
      debugPrint('Camera permission status: $cameraStatus');

      // Only request permission if not granted and not permanently denied
      if (!cameraStatus.isGranted && !cameraStatus.isPermanentlyDenied) {
        debugPrint('Requesting camera permission...');
        final result = await Permission.camera.request();
        debugPrint('Camera permission request result: $result');
        if (!result.isGranted) {
          debugPrint('Camera permission denied - returning silently');
          // Don't show error for first-time denial, just return silently
          return;
        }
      }

      // If permanently denied, show settings dialog
      if (cameraStatus.isPermanentlyDenied) {
        debugPrint(
            'Camera permission permanently denied - showing settings dialog');
        _showPermissionError(context,
            'Camera permission is required. Please enable it in settings.');
        return;
      }

      // For Android, storage permission is only needed for older versions
      // On Android 11+ (API 30+), camera can save to app's private directory without storage permission
      if (Platform.isAndroid) {
        // Check if we're on Android 11+ (API 30+)
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        debugPrint('Android SDK version: $sdkInt');

        // Only request storage permission on Android 10 and below (API 29 and below)
        if (sdkInt <= 29) {
          final storageStatus = await Permission.storage.status;
          debugPrint('Storage permission status: $storageStatus');

          // Only request if not granted and not permanently denied
          if (!storageStatus.isGranted && !storageStatus.isPermanentlyDenied) {
            debugPrint('Requesting storage permission for Android $sdkInt...');
            final result = await Permission.storage.request();
            debugPrint('Storage permission request result: $result');
            if (!result.isGranted) {
              debugPrint('Storage permission denied - returning silently');
              // Don't show error for first-time denial, just return silently
              return;
            }
          }

          // If permanently denied, show settings dialog
          if (storageStatus.isPermanentlyDenied) {
            debugPrint(
                'Storage permission permanently denied - showing settings dialog');
            _showPermissionError(context,
                'Storage permission is required. Please enable it in settings.');
            return;
          }
        } else {
          debugPrint(
              'Android 11+ detected - storage permission not required for camera');
        }
      }

      debugPrint('All permissions granted - proceeding with camera capture');

      // Proceed with camera capture
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        debugPrint('Image captured from camera: ${image.path}');
        _setPreviewImage(image); // Set preview image
      } else {
        debugPrint('No image selected from camera');
      }
    } catch (e) {
      debugPrint('Error in camera capture: $e');
      _showError(context, 'Failed to capture from camera: $e');
    }
  }

  /// Capture photo from gallery
  Future<void> _captureFromGallery(BuildContext context, WidgetRef ref) async {
    debugPrint('Gallery button pressed - starting gallery selection');

    try {
      // Reset any previous error state
      ref.read(photoCaptureNotifierProvider.notifier).reset();

      // Check appropriate permissions based on platform
      if (Platform.isAndroid) {
        // Check Android version to determine which permissions are needed
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        debugPrint('Android SDK version: $sdkInt');

        if (sdkInt >= 33) {
          // Android 13+ (API 33+): Use READ_MEDIA_IMAGES permission
          final photosStatus = await Permission.photos.status;
          debugPrint('Photos permission status: $photosStatus');

          // Only request if not granted and not permanently denied
          if (!photosStatus.isGranted && !photosStatus.isPermanentlyDenied) {
            debugPrint('Requesting photos permission for Android $sdkInt...');
            final result = await Permission.photos.request();
            debugPrint('Photos permission request result: $result');
            if (!result.isGranted) {
              debugPrint('Photos permission denied - returning silently');
              // Don't show error for first-time denial, just return silently
              return;
            }
          }

          // If permanently denied, show settings dialog
          if (photosStatus.isPermanentlyDenied) {
            debugPrint(
                'Photos permission permanently denied - showing settings dialog');
            _showPermissionError(context,
                'Photos permission is required. Please enable it in settings.');
            return;
          }
        } else if (sdkInt >= 30) {
          // Android 11-12 (API 30-32): Use READ_EXTERNAL_STORAGE permission
          final storageStatus = await Permission.storage.status;
          debugPrint('Storage permission status: $storageStatus');

          // Only request if not granted and not permanently denied
          if (!storageStatus.isGranted && !storageStatus.isPermanentlyDenied) {
            debugPrint('Requesting storage permission for Android $sdkInt...');
            final result = await Permission.storage.request();
            debugPrint('Storage permission request result: $result');
            if (!result.isGranted) {
              debugPrint('Storage permission denied - returning silently');
              // Don't show error for first-time denial, just return silently
              return;
            }
          }

          // If permanently denied, show settings dialog
          if (storageStatus.isPermanentlyDenied) {
            debugPrint(
                'Storage permission permanently denied - showing settings dialog');
            _showPermissionError(context,
                'Storage permission is required. Please enable it in settings.');
            return;
          }
        } else {
          // Android 10 and below (API 29 and below): Use READ_EXTERNAL_STORAGE permission
          final storageStatus = await Permission.storage.status;
          debugPrint('Storage permission status: $storageStatus');

          // Only request if not granted and not permanently denied
          if (!storageStatus.isGranted && !storageStatus.isPermanentlyDenied) {
            debugPrint('Requesting storage permission for Android $sdkInt...');
            final result = await Permission.storage.request();
            debugPrint('Storage permission request result: $result');
            if (!result.isGranted) {
              debugPrint('Storage permission denied - returning silently');
              // Don't show error for first-time denial, just return silently
              return;
            }
          }

          // If permanently denied, show settings dialog
          if (storageStatus.isPermanentlyDenied) {
            debugPrint(
                'Storage permission permanently denied - showing settings dialog');
            _showPermissionError(context,
                'Storage permission is required. Please enable it in settings.');
            return;
          }
        }
      } else if (Platform.isIOS) {
        // For iOS, check photos permission
        final photosStatus = await Permission.photos.status;
        debugPrint('Photos permission status: $photosStatus');

        // Only request if not granted and not permanently denied
        if (!photosStatus.isGranted && !photosStatus.isPermanentlyDenied) {
          debugPrint('Requesting photos permission...');
          final result = await Permission.photos.request();
          debugPrint('Photos permission request result: $result');
          if (!result.isGranted) {
            debugPrint('Photos permission denied - returning silently');
            // Don't show error for first-time denial, just return silently
            return;
          }
        }

        // If permanently denied, show settings dialog
        if (photosStatus.isPermanentlyDenied) {
          debugPrint(
              'Photos permission permanently denied - showing settings dialog');
          _showPermissionError(context,
              'Photos permission is required. Please enable it in settings.');
          return;
        }
      }

      debugPrint('All permissions granted - proceeding with gallery selection');

      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        debugPrint('Image selected from gallery: ${image.path}');
        _setPreviewImage(image); // Set preview image
      } else {
        debugPrint('No image selected from gallery');
      }
    } catch (e) {
      debugPrint('Error in gallery capture: $e');
      _showError(context, 'Failed to capture from gallery: $e');
    }
  }

  /// Process the captured image
  Future<void> _processCapturedImage(
      BuildContext context, WidgetRef ref, XFile image) async {
    debugPrint('Processing captured image: ${image.path}');

    try {
      final file = File(image.path);

      // Check if file exists
      if (!await file.exists()) {
        debugPrint('Selected image file does not exist: ${image.path}');
        _showError(context, 'Selected image file does not exist.');
        return;
      }

      final fileSize = await file.length();
      final fileName = image.name;
      final mimeType = _getMimeType(fileName);

      debugPrint(
          'Image details - Size: $fileSize bytes, Name: $fileName, MIME: $mimeType');

      // Validate file size (10MB limit)
      if (fileSize > 10 * 1024 * 1024) {
        debugPrint('File size too large: $fileSize bytes');
        _showError(context, 'File size too large. Maximum size is 10MB.');
        return;
      }

      // Validate MIME type
      if (!_isValidMimeType(mimeType)) {
        debugPrint('Invalid MIME type: $mimeType');
        _showError(context,
            'Unsupported file type. Please select a JPEG or PNG image.');
        return;
      }

      debugPrint('Image validation passed - proceeding with capture');

      // Capture the photo using the use case
      final notifier = ref.read(photoCaptureNotifierProvider.notifier);
      debugPrint(
          'Calling capturePhoto use case with expenseId: ${widget.expenseId}');

      await notifier.capturePhoto(
        expenseId: widget.expenseId,
        filePath: image.path,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType,
        capturedAt: DateTime.now(),
      );

      debugPrint('Capture photo call completed - checking result');

      // Check the result
      final state = ref.read(photoCaptureNotifierProvider);
      debugPrint('Photo capture state: $state');

      state.whenData((result) {
        debugPrint('Photo capture result: $result');
        result?.fold(
          (failure) {
            debugPrint('Photo capture failed: ${failure.message}');
            _showError(context, failure.message);
            widget.onError?.call();
          },
          (receiptPhoto) {
            debugPrint('Photo capture successful: ${receiptPhoto.id}');
            widget.onPhotoCaptured?.call();
            // Reset the state after successful capture
            Future.delayed(const Duration(seconds: 2), () {
              notifier.reset();
            });
          },
        );
      });
    } catch (e) {
      debugPrint('Error processing image: $e');
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
    widget.onError?.call();
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
    widget.onError?.call();
  }
}
