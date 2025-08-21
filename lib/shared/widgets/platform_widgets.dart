// This file provides platform-adaptive UI components that automatically adapt to iOS and Android.
// It encapsulates platform-specific differences and provides a unified interface for the app.
// This demonstrates proper platform adaptation and code reuse across different platforms.

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import '../../l10n/app_localizations.dart';

/// Utility class that provides platform-adaptive UI components.
/// This class abstracts platform differences and provides consistent widgets across iOS and Android.
class PlatformWidgets {
  // Platform detection properties
  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;

  /// Builds a platform-adaptive AppBar that looks native on both iOS and Android.
  /// iOS uses CupertinoNavigationBar, Android uses Material AppBar.
  static PreferredSizeWidget buildAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
  }) {
    if (isIOS) {
      // iOS: Use CupertinoNavigationBar for native iOS look
      return CupertinoNavigationBar(
        middle: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: actions != null && actions.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: actions,
              )
            : null,
        leading: leading,
      );
    } else {
      // Android: Use Material AppBar for native Android look
      return AppBar(
        title: Text(title),
        actions: actions,
        leading: leading,
        centerTitle: centerTitle,
      );
    }
  }

  /// Builds a platform-adaptive Scaffold that provides the basic app structure.
  /// iOS uses CupertinoPageScaffold, Android uses Material Scaffold.
  static Widget buildScaffold({
    required BuildContext context,
    PreferredSizeWidget? appBar,
    required Widget body,
    Widget? floatingActionButton,
    Widget? bottomNavigationBar,
    Widget? drawer,
    Widget? endDrawer,
    bool? resizeToAvoidBottomInset,
  }) {
    if (isIOS) {
      // iOS: Use CupertinoPageScaffold with SafeArea
      return CupertinoPageScaffold(
        navigationBar: appBar as CupertinoNavigationBar?,
        child: SafeArea(
          child: body,
        ),
      );
    } else {
      // Android: Use Material Scaffold with all Material features
      return Scaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        drawer: drawer,
        endDrawer: endDrawer,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      );
    }
  }

  /// Builds a platform-adaptive button that follows platform design guidelines.
  /// iOS uses CupertinoButton, Android uses Material ElevatedButton.
  static Widget buildButton({
    required BuildContext context,
    required VoidCallback? onPressed,
    required Widget child,
    bool isPrimary = true,
    bool isLoading = false,
  }) {
    if (isIOS) {
      // iOS: Use CupertinoButton with appropriate styling
      return CupertinoButton(
        onPressed: isLoading ? null : onPressed,
        color: isPrimary
            ? CupertinoColors.activeBlue
            : CupertinoColors.systemGrey5,
        child: isLoading
            ? const CupertinoActivityIndicator(color: CupertinoColors.white)
            : child,
      );
    } else {
      // Android: Use Material ElevatedButton with appropriate styling
      return ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          foregroundColor: isPrimary
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : child,
      );
    }
  }

  /// Builds a platform-adaptive action button (icon button) for app bars and other UI elements.
  /// iOS uses CupertinoButton, Android uses Material IconButton.
  static Widget platformActionButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback? onPressed,
    String? tooltip,
  }) {
    if (isIOS) {
      // iOS: Use CupertinoButton with icon
      return CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        child: Icon(icon),
      );
    } else {
      // Android: Use Material IconButton with tooltip
      return IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        tooltip: tooltip,
      );
    }
  }

  /// Builds a platform-adaptive text field that follows platform input guidelines.
  /// iOS uses CupertinoTextField, Android uses Material TextField.
  static Widget buildTextField({
    required BuildContext context,
    required String label,
    String? hint,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextInputType? keyboardType,
  }) {
    if (isIOS) {
      // iOS: Use CupertinoTextField with iOS styling
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: CupertinoTextField(
          controller: controller,
          placeholder: hint,
          onChanged: onChanged,
          keyboardType: keyboardType,
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.separator),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } else {
      // Android: Use Material TextField with Material styling
      return TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
        onChanged: onChanged,
        keyboardType: keyboardType,
      );
    }
  }

  /// Builds a platform-adaptive dropdown that follows platform selection guidelines.
  /// iOS uses CupertinoPicker, Android uses Material DropdownButtonFormField.
  static Widget buildPlatformDropdown<T>({
    required BuildContext context,
    required T? value,
    required List<T> items,
    required Widget Function(T) itemBuilder,
    required void Function(T?) onChanged,
    String? label,
  }) {
    if (isIOS) {
      // iOS: Use CupertinoPicker in a modal bottom sheet
      return GestureDetector(
        onTap: () {
          showCupertinoModalPopup(
            context: context,
            builder: (context) => Container(
              height: 200,
              color: CupertinoColors.systemBackground,
              child: Column(
                children: [
                  Container(
                    height: 40,
                    color: CupertinoColors.systemGrey6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
                          onPressed: () => Navigator.pop(context),
                        ),
                        CupertinoButton(
                          child: Text(AppLocalizations.of(context)?.done ?? 'Done'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 40,
                      onSelectedItemChanged: (index) {
                        onChanged(items[index]);
                      },
                      children: items.map(itemBuilder).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.separator),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value?.toString() ?? 'Select'),
              const Icon(CupertinoIcons.chevron_down),
            ],
          ),
        ),
      );
    } else {
      // Android: Use Material DropdownButtonFormField
      return DropdownButtonFormField<T>(
        value: value,
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: itemBuilder(item),
                ))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );
    }
  }

  /// Builds a platform-adaptive list tile that follows platform list guidelines.
  /// iOS uses CupertinoListTile, Android uses Material ListTile.
  static Widget platformListTile({
    required BuildContext context,
    required Widget title,
    Widget? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    if (isIOS) {
      // iOS: Use CupertinoListTile with iOS styling
      return CupertinoListTile(
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
      );
    } else {
      // Android: Use Material ListTile with Material styling
      return ListTile(
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
      );
    }
  }

  /// Builds a platform-adaptive switch that follows platform toggle guidelines.
  /// iOS uses CupertinoSwitch, Android uses Material Switch.
  static Widget buildSwitch({
    required BuildContext context,
    required bool value,
    required void Function(bool) onChanged,
    String? title,
  }) {
    if (isIOS) {
      // iOS: Use CupertinoSwitch with optional title
      return title != null
          ? CupertinoListTile(
              title: Text(title),
              trailing: CupertinoSwitch(
                value: value,
                onChanged: onChanged,
              ),
            )
          : CupertinoSwitch(
              value: value,
              onChanged: onChanged,
            );
    } else {
      // Android: Use Material Switch with optional title
      return title != null
          ? ListTile(
              title: Text(title),
              trailing: Switch(
                value: value,
                onChanged: onChanged,
              ),
            )
          : Switch(
              value: value,
              onChanged: onChanged,
            );
    }
  }

  /// Shows a platform-adaptive date picker that follows platform selection guidelines.
  /// iOS uses CupertinoDatePicker, Android uses Material showDatePicker.
  static Future<DateTime?> showPlatformDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    if (isIOS) {
      // iOS: Use CupertinoDatePicker in a modal bottom sheet
      return showCupertinoModalPopup<DateTime>(
        context: context,
        builder: (context) => Container(
          height: 300,
          color: CupertinoColors.systemBackground,
          child: Column(
            children: [
              Container(
                height: 40,
                color: CupertinoColors.systemGrey6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: Text(AppLocalizations.of(context)?.done ?? 'Done'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initialDate,
                  minimumDate: firstDate,
                  maximumDate: lastDate,
                  onDateTimeChanged: (date) {
                    // Store the selected date and return it when Done is pressed
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Android: Use Material showDatePicker
      return showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      );
    }
  }

  /// Shows a platform-adaptive snackbar that follows platform notification guidelines.
  /// iOS uses CupertinoAlertDialog, Android uses Material SnackBar.
  static void showPlatformSnackbar({
    required BuildContext context,
    required String message,
  }) {
    if (isIOS) {
      // iOS: Use CupertinoAlertDialog for important messages
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      // Android: Use Material SnackBar for notifications
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  /// Shows a platform-adaptive loading indicator that follows platform loading guidelines.
  /// iOS uses CupertinoActivityIndicator, Android uses Material CircularProgressIndicator.
  static Widget buildLoadingIndicator() {
    if (isIOS) {
      return const CupertinoActivityIndicator();
    } else {
      return const CircularProgressIndicator();
    }
  }
}
