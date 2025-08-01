// This file defines the PhotoDisplayWidget for displaying receipt photos.
// It provides a user interface for viewing and managing photos attached to expenses.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'dart:io';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/errors/failures.dart';
import '../providers/photo_providers.dart';
import '../../domain/entities/receipt_photo.dart';

/// Widget for displaying photos attached to an expense.
/// Shows a list of photos with options to view and delete them.
class PhotoDisplayWidget extends ConsumerWidget {
  final String expenseId;
  final VoidCallback? onPhotoDeleted;

  const PhotoDisplayWidget({
    super.key,
    required this.expenseId,
    this.onPhotoDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(photosForExpenseProvider(expenseId));
    final photoDeletionState = ref.watch(photoDeletionNotifierProvider);

    return photosAsync.when(
      data: (photos) {
        if (photos.isEmpty) {
          return _buildNoPhotosSection(context);
        }

        return _buildPhotosSection(context, ref, photos, photoDeletionState);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          _buildErrorSection(context, ref, error.toString()),
    );
  }

  /// Build section when no photos are attached
  Widget _buildNoPhotosSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.photo_library_outlined,
            color: Theme.of(context).colorScheme.outline,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context)?.noPhotos ?? 'No photos attached',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  /// Build section when photos are attached
  Widget _buildPhotosSection(
    BuildContext context,
    WidgetRef ref,
    List<ReceiptPhoto> photos,
    AsyncValue<Either<Failure, void>?> photoDeletionState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Icon(
                Icons.photo_library,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)?.receiptPhotos ?? 'Receipt Photos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Text(
                '${photos.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),

        // Photos grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            return _buildPhotoThumbnail(
                context, ref, photo, photoDeletionState);
          },
        ),

        // Loading indicator for deletion
        if (photoDeletionState.isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),

        // Error message for deletion
        if (photoDeletionState.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Error: ${photoDeletionState.error}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  /// Build individual photo thumbnail
  Widget _buildPhotoThumbnail(
    BuildContext context,
    WidgetRef ref,
    ReceiptPhoto photo,
    AsyncValue<Either<Failure, void>?> photoDeletionState,
  ) {
    return GestureDetector(
      onTap: () => _showPhotoFullScreen(context, photo),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Stack(
          children: [
            // Photo thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.file(
                File(photo.filePath),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: Icon(
                      Icons.broken_image,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  );
                },
              ),
            ),

            // Delete button
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _deletePhoto(context, ref, photo),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onError,
                    size: 16,
                  ),
                ),
              ),
            ),

            // File size indicator
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatFileSize(photo.fileSize),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error section
  Widget _buildErrorSection(BuildContext context, WidgetRef ref, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error loading photos',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // Refresh the photos
              ref.invalidate(photosForExpenseProvider(expenseId));
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Show photo in full screen
  void _showPhotoFullScreen(BuildContext context, ReceiptPhoto photo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(photo.fileName),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              child: Image.file(
                File(photo.filePath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 64,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Delete photo
  Future<void> _deletePhoto(
      BuildContext context, WidgetRef ref, ReceiptPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppLocalizations.of(context)?.delete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notifier = ref.read(photoDeletionNotifierProvider.notifier);
      await notifier.deletePhoto(photo.id);

      // Check the result
      final state = ref.read(photoDeletionNotifierProvider);
      state.whenData((result) {
        result?.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          },
          (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    AppLocalizations.of(context)?.photoDeletedSuccessfully ??
                        'Photo deleted successfully!'),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
            onPhotoDeleted?.call();
            // Reset the state after successful deletion
            Future.delayed(const Duration(seconds: 2), () {
              notifier.reset();
            });
          },
        );
      });
    }
  }

  /// Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }
}
