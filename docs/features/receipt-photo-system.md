# Receipt Photo System Documentation

## Overview

The Receipt Photo System enhances the expense tracking experience by allowing users to capture, store, and manage photos of receipts. This feature provides visual proof of expenses and improves expense management accuracy.

## Architecture

### Domain Layer

- **Entity**: `ReceiptPhoto` - Core business object representing a receipt photo
- **Repository**: `ReceiptPhotoRepository` - Interface for photo data operations
- **Use Cases**:
  - `CapturePhoto` - Captures photos from camera
  - `SavePhoto` - Saves photos to local storage
  - `GetPhotosForExpense` - Retrieves photos for specific expenses

### Data Layer

- **Model**: `ReceiptPhotoModel` - Hive-compatible data model
- **Repository Implementation**: `ReceiptPhotoRepositoryImpl` - Concrete implementation
- **Data Source**: `ReceiptPhotoLocalDataSource` - Local storage operations

### Presentation Layer

- **Widgets**:
  - `PhotoCaptureWidget` - Camera interface for photo capture
  - `PhotoDisplayWidget` - Displays captured photos
- **Providers**: `PhotoProviders` - State management with Riverpod

## Features

### 1. Photo Capture

- Direct camera integration
- Gallery photo selection
- Image quality optimization
- File size management (max 10MB)

### 2. Photo Storage

- Local storage with Hive database
- Efficient file management
- Automatic file naming and organization
- Backup and restore capabilities

### 3. Photo Display

- Thumbnail generation
- Full-screen photo viewing
- Photo gallery interface
- Swipe navigation between photos

### 4. Photo Management

- Delete photos
- Reorder photos
- Photo metadata tracking
- Association with specific expenses

## Usage

### Capturing Photos

1. Navigate to Add/Edit Expense screen
2. Tap "Camera" or "Gallery" button
3. For camera:
   - Point camera at receipt
   - Tap capture button
   - Review and confirm photo
4. For gallery:
   - Select photo from device gallery
   - Confirm selection

### Managing Photos

- View photos in expense details
- Tap photo for full-screen view
- Swipe between multiple photos
- Delete unwanted photos
- Reorder photos by dragging

### Photo Integration

- Photos automatically linked to expenses
- Visual indicators show photo count
- Quick access to photos from expense list
- Search and filter by photo presence

## Technical Implementation

### Data Model

```dart
class ReceiptPhoto {
  final String id;
  final String expenseId;
  final String filePath;
  final String fileName;
  final int fileSize;
  final DateTime capturedAt;
  final DateTime createdAt;
}
```

### File Management

- Photos stored in app's private directory
- Automatic file size validation
- Image compression for storage efficiency
- Thumbnail generation for performance

### Camera Integration

- Uses `image_picker` package
- Platform-specific camera implementation
- Permission handling for camera access
- Error handling for capture failures

### State Management

- Riverpod providers for photo state
- Reactive updates when photos change
- Efficient memory management
- Background processing for large files

## Security & Privacy

### Data Protection

- Photos stored in app's private directory
- No external access without user permission
- Secure file deletion
- Privacy-compliant storage

### Permissions

- Camera permission request
- Gallery access permission
- Storage permission for file management
- Graceful permission denial handling

## Performance Considerations

### Image Optimization

- Automatic image compression
- Thumbnail generation for lists
- Lazy loading of full-size images
- Memory-efficient image caching

### Storage Management

- File size limits (10MB max)
- Automatic cleanup of orphaned files
- Efficient database queries
- Background file operations

## Testing

- Unit tests for photo capture logic
- Widget tests for photo UI components
- Integration tests for camera/gallery
- File system operation tests
- Permission handling tests

## Error Handling

- Camera access failures
- File system errors
- Storage space issues
- Network connectivity problems
- Permission denial scenarios

## Accessibility

- Screen reader support
- High contrast mode compatibility
- Voice control integration
- Alternative input methods
