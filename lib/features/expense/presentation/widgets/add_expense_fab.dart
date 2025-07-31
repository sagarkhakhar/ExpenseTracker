// This file defines the AddExpenseFAB widget, which provides a floating action button for adding expenses.
// It handles navigation to the add expense screen and provides visual feedback.
// This demonstrates proper FAB implementation and navigation patterns.

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/platform_widgets.dart';
import '../views/add_expense_screen.dart';
import '../../../../l10n/app_localizations.dart';

/// A floating action button widget that navigates to the add expense screen.
/// Provides a consistent way to add new expenses throughout the app.
class AddExpenseFAB extends ConsumerWidget {
  const AddExpenseFAB({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;

    return FloatingActionButton(
      // Use platform-appropriate icon
      onPressed: () => _navigateToAddExpense(context),
      // Add tooltip for accessibility
      tooltip: localizations.addExpense,
      // Use platform-appropriate styling
      backgroundColor: PlatformWidgets.isIOS
          ? CupertinoColors.activeBlue
          : Theme.of(context).colorScheme.primary,
      foregroundColor: PlatformWidgets.isIOS
          ? CupertinoColors.white
          : Theme.of(context).colorScheme.onPrimary,
      // Use platform-appropriate icon
      child: Icon(
        PlatformWidgets.isIOS ? CupertinoIcons.add : Icons.add,
        size: AppConstants.iconSizeL,
      ),
    );
  }

  /// Navigates to the add expense screen with appropriate transition.
  /// Handles the navigation logic and provides user feedback.
  void _navigateToAddExpense(BuildContext context) {
    if (PlatformWidgets.isIOS) {
      // iOS-style navigation with slide transition
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => const AddExpenseScreen(),
          // Add slide transition for iOS feel
          fullscreenDialog: false,
        ),
      );
    } else {
      // Android-style navigation with material transition
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const AddExpenseScreen(),
          // Use material page route for Android feel
          fullscreenDialog: false,
        ),
      );
    }
  }
}

/// An extended floating action button that shows additional options.
/// Provides quick access to common expense categories.
class ExtendedAddExpenseFAB extends ConsumerStatefulWidget {
  const ExtendedAddExpenseFAB({super.key});

  @override
  ConsumerState<ExtendedAddExpenseFAB> createState() =>
      _ExtendedAddExpenseFABState();
}

class _ExtendedAddExpenseFABState extends ConsumerState<ExtendedAddExpenseFAB>
    with SingleTickerProviderStateMixin {
  // Animation controller for the extended FAB
  late AnimationController _animationController;
  // Track whether the FAB is expanded
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: AppConstants.animationNormal,
      vsync: this,
    );

    // Animation controller is ready for use
  }

  @override
  void dispose() {
    // Clean up animation controller
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Extended FAB options (shown when expanded)
        if (_isExpanded) ...[
          _buildQuickAddOption(
            context,
            'Quick Expense',
            PlatformWidgets.isIOS ? CupertinoIcons.minus : Icons.remove,
            const Color(AppConstants.errorColor),
            () => _navigateToQuickAdd(context, isExpense: true),
          ),
          const SizedBox(height: AppConstants.paddingS),
          _buildQuickAddOption(
            context,
            'Quick Income',
            PlatformWidgets.isIOS ? CupertinoIcons.plus : Icons.add,
            const Color(AppConstants.successColor),
            () => _navigateToQuickAdd(context, isExpense: false),
          ),
          const SizedBox(height: AppConstants.paddingS),
        ],

        // Main FAB button
        FloatingActionButton.extended(
          onPressed: _toggleExpansion,
          icon: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0, // 45 degrees when expanded
            duration: AppConstants.animationNormal,
            child: Icon(
              PlatformWidgets.isIOS ? CupertinoIcons.add : Icons.add,
              size: AppConstants.iconSizeL,
            ),
          ),
          label: Text(_isExpanded ? 'Close' : localizations.addExpense),
          backgroundColor: PlatformWidgets.isIOS
              ? CupertinoColors.activeBlue
              : Theme.of(context).colorScheme.primary,
          foregroundColor: PlatformWidgets.isIOS
              ? CupertinoColors.white
              : Theme.of(context).colorScheme.onPrimary,
        ),
      ],
    );
  }

  /// Builds a quick add option button for the extended FAB.
  /// Provides quick access to common expense/income types.
  Widget _buildQuickAddOption(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return AnimatedContainer(
      duration: AppConstants.animationNormal,
      height: _isExpanded ? AppConstants.heightButtonSmall : 0,
      child: AnimatedOpacity(
        duration: AppConstants.animationNormal,
        opacity: _isExpanded ? 1.0 : 0.0,
        child: FloatingActionButton.small(
          onPressed: onPressed,
          backgroundColor: color,
          foregroundColor: Colors.white,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppConstants.iconSizeS),
              const SizedBox(width: AppConstants.paddingXS),
              Text(
                label,
                style: const TextStyle(fontSize: AppConstants.textSizeS),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Toggles the expansion state of the extended FAB.
  /// Handles the animation and state changes.
  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  /// Navigates to a quick add screen with pre-filled expense type.
  /// Provides a streamlined experience for common expense types.
  void _navigateToQuickAdd(BuildContext context, {required bool isExpense}) {
    // Close the extended FAB
    _toggleExpansion();

    // Navigate to add expense screen
    if (PlatformWidgets.isIOS) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => const AddExpenseScreen(),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const AddExpenseScreen(),
        ),
      );
    }
  }
}
