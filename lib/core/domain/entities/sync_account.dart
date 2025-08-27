import 'package:hive/hive.dart';
import '../base_entity.dart';

part 'sync_account.g.dart';

/// Account types supported by the system
@HiveType(typeId: 22)
enum AccountType {
  @HiveField(0)
  cash,
  
  @HiveField(1)
  bank,
  
  @HiveField(2)
  creditCard,
  
  @HiveField(3)
  savings,
  
  @HiveField(4)
  investment,
  
  @HiveField(5)
  other,
}

/// Sync-enabled Account entity with BaseEntity fields
@HiveType(typeId: 23)
class SyncAccount extends BaseEntity {
  /// Business logic fields
  @HiveField(0)
  final String name;
  
  @HiveField(1)
  final AccountType type;
  
  @HiveField(2)
  final double balance; // Current balance
  
  @HiveField(3)
  final String? description;
  
  @HiveField(4)
  final String? currency; // ISO currency code (USD, EUR, etc.)
  
  @HiveField(5)
  final bool isActive; // Whether account is active

  /// BaseEntity sync fields
  @override
  @HiveField(6)
  final String id;
  
  @override
  @HiveField(7)
  final DateTime createdAt;
  
  @override
  @HiveField(8)
  final DateTime updatedAt;
  
  @override
  @HiveField(9)
  final int version;
  
  @override
  @HiveField(10)
  final bool isDeleted;
  
  @override
  @HiveField(11)
  final String? deviceId;
  
  @override
  @HiveField(12)
  final String? lastEditor;

  const SyncAccount({
    // Business fields
    required this.name,
    required this.type,
    required this.balance,
    this.description,
    this.currency = 'USD',
    this.isActive = true,
    // BaseEntity fields
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.isDeleted = false,
    this.deviceId,
    this.lastEditor,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
          version: version,
          isDeleted: isDeleted,
          deviceId: deviceId,
          lastEditor: lastEditor,
        );

  @override
  List<Object?> get props => [
        ...super.props,
        name,
        type,
        balance,
        description,
        currency,
        isActive,
      ];

  @override
  SyncAccount copyWithSyncMetadata({
    DateTime? updatedAt,
    int? version,
    bool? isDeleted,
    String? deviceId,
    String? lastEditor,
  }) {
    return copyWith(
      updatedAt: updatedAt,
      version: version,
      isDeleted: isDeleted,
      deviceId: deviceId,
      lastEditor: lastEditor,
    );
  }

  SyncAccount copyWith({
    String? name,
    AccountType? type,
    double? balance,
    String? description,
    String? currency,
    bool? isActive,
    DateTime? updatedAt,
    int? version,
    bool? isDeleted,
    String? deviceId,
    String? lastEditor,
  }) {
    return SyncAccount(
      // Business fields
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      description: description ?? this.description,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      // BaseEntity fields
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      isDeleted: isDeleted ?? this.isDeleted,
      deviceId: deviceId ?? this.deviceId,
      lastEditor: lastEditor ?? this.lastEditor,
    );
  }

  /// Create new account with sync metadata
  factory SyncAccount.create({
    required String name,
    required AccountType type,
    required String deviceId,
    required String lastEditor,
    double balance = 0.0,
    String? description,
    String currency = 'USD',
    bool isActive = true,
  }) {
    final now = EntityUtils.now();
    return SyncAccount(
      name: name,
      type: type,
      balance: balance,
      description: description,
      currency: currency,
      isActive: isActive,
      id: EntityUtils.generateId(),
      createdAt: now,
      updatedAt: now,
      version: 1,
      deviceId: deviceId,
      lastEditor: lastEditor,
    );
  }

  /// Update balance (creates new version)
  SyncAccount updateBalance(
    double newBalance, {
    required String deviceId,
    required String lastEditor,
  }) {
    return copyWith(
      balance: newBalance,
      updatedAt: EntityUtils.now(),
      version: version + 1,
      deviceId: deviceId,
      lastEditor: lastEditor,
    );
  }

  @override
  int get syncPriority => 1; // Accounts are important for expense tracking
}