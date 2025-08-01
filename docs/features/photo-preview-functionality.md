# Photo Preview Functionality

## Overview

The photo preview functionality has been implemented in the `PhotoCaptureWidget` to provide users with a preview of selected images before saving them to the expense. This enhances the user experience by allowing users to review and confirm their photo selection before it's permanently saved.

## Features

### Preview Mode

- When a user selects an image from camera or gallery, the widget switches to preview mode
- The selected image is displayed in a compact preview container with a height of 120px
- The image filename is shown in the preview header with text overflow handling
- Preview mode replaces the camera/gallery buttons with save/cancel options

### User Interface

- **Preview Header**: Shows a preview icon, "Preview" label, and the filename (with ellipsis for long names)
- **Image Display**: Shows the selected image with proper aspect ratio and error handling
- **Action Buttons**:
  - **Save**: Saves the image to the expense and exits preview mode
  - **Cancel**: Discards the image and returns to capture mode

### Validation

- File existence check before saving
- File size validation (10MB limit)
- MIME type validation (JPEG, PNG, HEIC, HEIF)
- Proper error messages for validation failures

### State Management

- Uses `ConsumerStatefulWidget` to manage preview state
- `_previewImage`: Stores the selected XFile
- `_isPreviewMode`: Boolean flag to control UI state

### Workflow

1. User taps Camera or Gallery button
2. Image picker opens and user selects an image
3. Widget switches to preview mode showing the selected image
4. User can save the image or cancel and return to capture mode
5. After saving, the photo is processed and saved to the expense
6. User can continue adding more photos

### Error Handling

- Graceful handling of missing files
- File size and type validation
- Permission request handling for camera and gallery access
- Settings dialog for permanently denied permissions

### Compact Design

- Reduced preview height from 200px to 120px for better space utilization
- Smaller padding and margins for a more compact appearance
- Efficient use of screen real estate

### Responsive Layout

- Flexible text containers to handle varying filename lengths
- Proper spacing and alignment for different screen sizes

## Localization

The following localization keys have been added:

- `preview`: "Preview" (English) / "Vista previa" (Spanish)
- `save`: "Save" (English) / "Guardar" (Spanish)

## Testing

The functionality includes comprehensive tests:

- Initial state verification (no preview elements)
- Button functionality testing
- Preview mode state management
- Error handling scenarios
- Permission request handling

## Technical Implementation

### Key Components

- **PhotoCaptureWidget**: Main widget with preview functionality
- **Preview Section**: Compact image display with save/cancel actions
- **State Management**: Local state for preview mode

### File Structure

```
lib/features/expense/presentation/widgets/
├── photo_capture_widget.dart          # Main widget with preview functionality
└── photo_display_widget.dart          # Display widget for saved photos
```

### Dependencies

- `image_picker`: For camera and gallery access
- `permission_handler`: For permission management
- `flutter_riverpod`: For state management
- `device_info_plus`: For device-specific functionality

## Usage

The widget is used in the add expense screen to provide photo capture functionality:

```dart
PhotoCaptureWidget(
  expenseId: expenseId,
  onPhotoCaptured: () {
    // Handle successful photo capture
  },
  onError: () {
    // Handle errors
  },
)
```

## Future Enhancements

- Photo deletion functionality
- Photo editing capabilities
- Bulk photo operations
- Photo compression options
- Cloud storage integration
- Saved photos thumbnails display
