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
/// Uses lazy loading to avoid performance issues.
class PhotoDisplayWidget extends ConsumerStatefulWidget {
  final String expenseId;
  final VoidCallback? onPhotoDeleted;
  final bool loadImmediately;

  const PhotoDisplayWidget({
    super.key,
    required this.expenseId,
    this.onPhotoDeleted,
    this.loadImmediately = false,
  });

  @override
  ConsumerState<PhotoDisplayWidget> createState() => _PhotoDisplayWidgetState();
}

class _PhotoDisplayWidgetState extends ConsumerState<PhotoDisplayWidget> {
  bool _shouldLoadPhotos = false;

  @override
  void initState() {
    super.initState();
    _shouldLoadPhotos = widget.loadImmediately;
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldLoadPhotos) {
      return _buildLazyLoadPlaceholder(context);
    }

    final photosAsync = ref.watch(photosForExpenseProvider(widget.expenseId));
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

  /// Build lazy loading placeholder to avoid initializing photos unnecessarily
  Widget _buildLazyLoadPlaceholder(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _shouldLoadPhotos = true;
          });
        },
        child: Row(
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Tap to load photos',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
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

        // Photos list - using a more compact thumbnail layout
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child:
                  _buildPhotoThumbnail(context, ref, photo, photoDeletionState),
            );
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

  /// Build individual photo thumbnail with compact design
  Widget _buildPhotoThumbnail(
    BuildContext context,
    WidgetRef ref,
    ReceiptPhoto photo,
    AsyncValue<Either<Failure, void>?> photoDeletionState,
  ) {
    return GestureDetector(
      onTap: () => _showPhotoFullScreen(context, photo),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
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
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Theme.of(context).colorScheme.outline,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Delete button - positioned in top right corner
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _deletePhoto(context, ref, photo),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),

            // File size indicator - positioned in bottom left corner
            Positioned(
              bottom: 8,
              left: 8,
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
                    fontWeight: FontWeight.w500,
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
              ref.invalidate(photosForExpenseProvider(widget.expenseId));
            },
            child: Text(AppLocalizations.of(context)!.retry),
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
        title: Text(AppLocalizations.of(context)!.deletePhoto),
        content: Text(AppLocalizations.of(context)!.deletePhotoConfirm),
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
            widget.onPhotoDeleted?.call();
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
