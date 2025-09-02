// Account domain entity for multi-account expense tracking
// Enables users to organize expenses by different accounts (cash, bank, credit, etc.)

import 'package:equatable/equatable.dart';

enum AccountType {
  checking,
  savings,
  credit,
  cash,
  investment,
  other;

  String get displayName {
    switch (this) {
      case AccountType.checking:
        return 'Checking Account';
      case AccountType.savings:
        return 'Savings Account';
      case AccountType.credit:
        return 'Credit Card';
      case AccountType.cash:
        return 'Cash';
      case AccountType.investment:
        return 'Investment Account';
      case AccountType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case AccountType.checking:
        return '🏦';
      case AccountType.savings:
        return '💰';
      case AccountType.credit:
        return '💳';
      case AccountType.cash:
        return '💵';
      case AccountType.investment:
        return '📈';
      case AccountType.other:
        return '📋';
    }
  }
}

class Account extends Equatable {
  final String id;
  final String userId;
  final String name;
  final AccountType accountType;
  final String currency;
  final double initialBalance;
  final double currentBalance;
  final bool isDefault;
  final bool isActive;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.accountType,
    required this.currency,
    required this.initialBalance,
    required this.currentBalance,
    required this.isDefault,
    required this.isActive,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of this account with some fields changed
  Account copyWith({
    String? id,
    String? userId,
    String? name,
    AccountType? accountType,
    String? currency,
    double? initialBalance,
    double? currentBalance,
    bool? isDefault,
    bool? isActive,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      currency: currency ?? this.currency,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get the net change from initial balance
  double get netChange => currentBalance - initialBalance;

  /// Check if this account has a positive balance
  bool get hasPositiveBalance => currentBalance >= 0;

  /// Get formatted account display name with type
  String get fullDisplayName => '$name (${accountType.displayName})';

  /// Update balance after a transaction
  Account updateBalance(double amount) {
    return copyWith(
      currentBalance: currentBalance + amount,
      updatedAt: DateTime.now(),
    );
  }

  /// Get active accounts from a list
  static List<Account> getActiveAccounts(List<Account> accounts) {
    return accounts.where((account) => account.isActive).toList();
  }

  /// Get default account from a list
  static Account? getDefaultAccount(List<Account> accounts) {
    try {
      return accounts.firstWhere((account) => account.isDefault && account.isActive);
    } catch (e) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        accountType,
        currency,
        initialBalance,
        currentBalance,
        isDefault,
        isActive,
        description,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() => 'Account(id: $id, name: $name, type: ${accountType.displayName})';
}