# Data Models and Schema Changes

## New Data Models

### Budget Model

**Purpose:** Store budget limits and tracking information for expense categories
**Integration:** Extends existing category system and integrates with expense tracking

**Key Attributes:**

- `id`: String (UUID) - Unique identifier for the budget
- `categoryId`: String - Reference to existing expense category
- `amount`: double - Budget limit amount
- `period`: String - Budget period (monthly, weekly, yearly)
- `startDate`: DateTime - When the budget period starts
- `endDate`: DateTime - When the budget period ends
- `spentAmount`: double - Current amount spent in this period
- `isActive`: bool - Whether this budget is currently active
- `createdAt`: DateTime - When the budget was created
- `updatedAt`: DateTime - When the budget was last updated

**Relationships:**

- **With Existing:** Links to existing expense categories via categoryId
- **With New:** Can be referenced by budget alerts and statistics

### Receipt Photo Model

**Purpose:** Store receipt photo metadata and file references
**Integration:** Extends existing expense model with photo attachment capability

**Key Attributes:**

- `id`: String (UUID) - Unique identifier for the receipt
- `expenseId`: String - Reference to existing expense record
- `fileName`: String - Name of the photo file
- `filePath`: String - Local file system path to the photo
- `fileSize`: int - Size of the photo file in bytes
- `mimeType`: String - MIME type of the photo (image/jpeg, image/png)
- `capturedAt`: DateTime - When the photo was taken
- `uploadedAt`: DateTime - When the photo was saved
- `thumbnailPath`: String - Path to thumbnail version (optional)
- `ocrData`: Map<String, dynamic> - OCR extracted data (optional)

**Relationships:**

- **With Existing:** Links to existing expense records via expenseId
- **With New:** Can be processed by OCR services and used in expense details

### User Settings Model

**Purpose:** Store user preferences and app configuration
**Integration:** Provides app-wide settings that affect existing functionality

**Key Attributes:**

- `id`: String (UUID) - Unique identifier for settings
- `currency`: String - Preferred currency code (USD, EUR, etc.)
- `defaultCategories`: List<String> - Default categories for new expenses
- `notificationPreferences`: Map<String, bool> - Notification settings
- `dataRetentionDays`: int - How long to keep data
- `themePreference`: String - Light, dark, or system
- `languageCode`: String - Preferred language (en, es)
- `exportFormat`: String - Preferred export format (CSV, JSON)
- `createdAt`: DateTime - When settings were created
- `updatedAt`: DateTime - When settings were last updated

**Relationships:**

- **With Existing:** Affects existing expense creation and display
- **With New:** Controls behavior of new features

### Export History Model

**Purpose:** Track data export operations for audit and user reference
**Integration:** Provides history of data export operations

**Key Attributes:**

- `id`: String (UUID) - Unique identifier for export record
- `exportType`: String - Type of export (CSV, JSON)
- `fileName`: String - Name of exported file
- `filePath`: String - Local path to exported file
- `recordCount`: int - Number of records exported
- `dateRange`: Map<String, DateTime> - Date range of exported data
- `exportedAt`: DateTime - When the export was performed
- `fileSize`: int - Size of exported file in bytes
- `status`: String - Export status (success, failed, in_progress)

**Relationships:**

- **With Existing:** References existing expense data that was exported
- **With New:** Can be used for export management and cleanup

## Schema Integration Strategy

**Database Changes Required:**

- **New Tables:** budgets, receipt_photos, user_settings, export_history
- **Modified Tables:** expenses (add photo reference field)
- **New Indexes:** budget_category_index, receipt_expense_index, settings_user_index
- **Migration Strategy:** Additive changes only, no breaking modifications to existing schema

**Backward Compatibility:**

- All existing expense data remains unchanged and accessible
- New fields in existing models are optional with default values
- Existing queries and data access patterns continue to work
- No data migration required for existing users

**Hive Integration Approach:**

- New models will use HiveType annotations following existing patterns
- Custom adapters will be created for new models
- New Hive boxes will be created for each new data type
- Existing expense box remains unchanged

**Data Flow Integration:**

- Budget data integrates with existing expense statistics calculations
- Receipt photos are stored separately but linked to expenses
- Settings affect existing UI and functionality globally
- Export history provides audit trail for data operations
