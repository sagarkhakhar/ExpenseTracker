import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

class PlatformWidgets {
  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;

  // Platform-adaptive AppBar
  static PreferredSizeWidget buildAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
  }) {
    if (isIOS) {
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
      return AppBar(
        title: Text(title),
        actions: actions,
        leading: leading,
        centerTitle: centerTitle,
      );
    }
  }

  // Platform-adaptive Scaffold
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
      return CupertinoPageScaffold(
        navigationBar: appBar as CupertinoNavigationBar?,
        child: SafeArea(
          child: body,
        ),
      );
    } else {
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

  // Platform-adaptive Button
  static Widget buildButton({
    required BuildContext context,
    required VoidCallback? onPressed,
    required Widget child,
    bool isPrimary = true,
    bool isLoading = false,
  }) {
    if (isIOS) {
      if (isPrimary) {
        return CupertinoButton.filled(
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
              : child,
        );
      } else {
        return CupertinoButton(
          onPressed: isLoading ? null : onPressed,
          child: isLoading ? const CupertinoActivityIndicator() : child,
        );
      }
    } else {
      if (isPrimary) {
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : child,
        );
      } else {
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
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
  }

  // Platform-adaptive Loading Indicator
  static Widget buildLoadingIndicator({Color? color}) {
    if (isIOS) {
      return CupertinoActivityIndicator(color: color);
    } else {
      return CircularProgressIndicator(
        valueColor: color != null ? AlwaysStoppedAnimation<Color>(color) : null,
      );
    }
  }

  // Platform-adaptive TextField
  static Widget buildTextField({
    required BuildContext context,
    required String label,
    String? hint,
    TextEditingController? controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
    int? maxLines,
    int? maxLength,
    bool enabled = true,
    void Function(String)? onChanged,
  }) {
    if (isIOS) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.label,
              ),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: controller,
              placeholder: hint,
              keyboardType: keyboardType,
              obscureText: obscureText,
              prefix: prefixIcon,
              suffix: suffixIcon,
              maxLines: maxLines,
              maxLength: maxLength,
              enabled: enabled,
              onChanged: onChanged,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: CupertinoColors.separator,
                  width: 0.5,
                ),
              ),
            ),
            if (validator != null)
              Builder(
                builder: (context) {
                  final error = validator(controller?.text);
                  if (error != null) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        error,
                        style: const TextStyle(
                          color: CupertinoColors.systemRed,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
          ],
        ),
      );
    } else {
      return TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
        ),
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        maxLength: maxLength,
        enabled: enabled,
        onChanged: onChanged,
      );
    }
  }

  // Platform-adaptive Switch
  static Widget buildSwitch({
    required BuildContext context,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? title,
    String? subtitle,
  }) {
    if (isIOS) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            if (title != null) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
            ],
            CupertinoSwitch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      );
    } else {
      return SwitchListTile(
        title: title != null ? Text(title) : null,
        subtitle: subtitle != null ? Text(subtitle) : null,
        value: value,
        onChanged: onChanged,
      );
    }
  }

  // Platform-adaptive Refresh Indicator
  static Widget buildRefreshIndicator({
    required Widget child,
    required Future<void> Function() onRefresh,
  }) {
    if (isIOS) {
      return CupertinoScrollbar(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: onRefresh),
            SliverToBoxAdapter(child: child),
          ],
        ),
      );
    } else {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: child,
      );
    }
  }

  // Platform-adaptive RefreshIndicator (for slivers on iOS)
  static Widget buildRefreshSliverIndicator({
    required List<Widget> slivers,
    required Future<void> Function() onRefresh,
  }) {
    if (isIOS) {
      return CupertinoScrollbar(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: onRefresh),
            ...slivers,
          ],
        ),
      );
    } else {
      // For Android, fallback to normal buildRefreshIndicator
      return buildRefreshIndicator(
        child: ListView(
          children: slivers
              .map((s) => s is SliverToBoxAdapter
                  ? s.child ?? const SizedBox.shrink()
                  : const SizedBox.shrink())
              .toList(),
        ),
        onRefresh: onRefresh,
      );
    }
  }

  // Platform-adaptive Action Button (for AppBar actions)
  static Widget platformActionButton({
    required BuildContext context,
    required VoidCallback? onPressed,
    required IconData icon,
    String? tooltip,
  }) {
    if (isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        minSize: 0,
        onPressed: onPressed,
        child: Icon(icon, size: 24),
      );
    } else {
      return IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
      );
    }
  }

  // Platform-adaptive ListTile
  static Widget platformListTile({
    required BuildContext context,
    Widget? leading,
    required Widget title,
    Widget? subtitle,
    Widget? trailing,
    GestureTapCallback? onTap,
    bool enabled = true,
    EdgeInsetsGeometry? contentPadding,
  }) {
    if (isIOS) {
      return GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: contentPadding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.transparent,
          child: Row(
            children: [
              if (leading != null) ...[
                leading,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      DefaultTextStyle(
                        style: const TextStyle(
                            color: CupertinoColors.systemGrey, fontSize: 13),
                        child: subtitle,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing,
              ],
            ],
          ),
        ),
      );
    } else {
      return ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: enabled ? onTap : null,
        contentPadding: contentPadding,
        enabled: enabled,
      );
    }
  }

  // Platform-adaptive Dialog (Alert/Confirmation)
  static Future<bool?> showPlatformDialog({
    required BuildContext context,
    required String title,
    required String content,
    String cancelText = 'Cancel',
    String confirmText = 'OK',
    bool showCancel = true,
    bool destructive = false,
  }) {
    if (isIOS) {
      return showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            if (showCancel)
              CupertinoDialogAction(
                child: Text(cancelText),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            CupertinoDialogAction(
              isDestructiveAction: destructive,
              child: Text(confirmText),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      );
    } else {
      return showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            if (showCancel)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(cancelText),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(confirmText,
                  style:
                      destructive ? const TextStyle(color: Colors.red) : null),
            ),
          ],
        ),
      );
    }
  }

  // Platform-adaptive Snackbar/Toast
  static void showPlatformSnackbar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: duration),
      );
    }
  }

  // Platform-adaptive Date Picker
  static Future<DateTime?> showPlatformDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    if (isIOS) {
      return showCupertinoModalPopup<DateTime>(
        context: context,
        builder: (ctx) => Container(
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
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () => Navigator.of(ctx).pop(_selectedDate),
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
                  onDateTimeChanged: (date) => _selectedDate = date,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      );
    }
  }

  // Platform-adaptive Dropdown
  static Widget buildPlatformDropdown<T>({
    required BuildContext context,
    required T? value,
    required List<T> items,
    required Widget Function(T) itemBuilder,
    required void Function(T?) onChanged,
    String? label,
    String? hint,
  }) {
    if (isIOS) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.label,
                ),
              ),
            ),
          GestureDetector(
            onTap: () {
              showCupertinoModalPopup<T>(
                context: context,
                builder: (ctx) => Container(
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
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                            CupertinoButton(
                              child: const Text('Done'),
                              onPressed: () =>
                                  Navigator.of(ctx).pop(_selectedDropdownValue),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 40,
                          onSelectedItemChanged: (index) {
                            _selectedDropdownValue = items[index];
                          },
                          children: items
                              .map((item) => Center(child: itemBuilder(item)))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ).then((selected) {
                if (selected != null) {
                  onChanged(selected);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: value != null
                        ? itemBuilder(value)
                        : Text(
                            hint ?? 'Select an option',
                            style: const TextStyle(
                                color: CupertinoColors.systemGrey),
                          ),
                  ),
                  const Icon(CupertinoIcons.chevron_down, size: 16),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
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
          hintText: hint,
        ),
      );
    }
  }
}

// Global variables for platform widgets
DateTime _selectedDate = DateTime.now();
dynamic _selectedDropdownValue;
