import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Base widget for authentication screens with consistent layout and platform detection
class AuthScreenBase extends StatelessWidget {
  const AuthScreenBase({
    super.key,
    required this.title,
    required this.child,
    this.showBackButton = false,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(24.0),
  });

  final String title;
  final Widget child;
  final bool showBackButton;
  final Color? backgroundColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final colorScheme = theme.colorScheme;
    
    // Determine if we should use safe area based on platform
    final useSafeArea = !kIsWeb && (Platform.isIOS || Platform.isAndroid);
    
    Widget content = Scaffold(
      backgroundColor: backgroundColor ?? colorScheme.surface,
      appBar: showBackButton
          ? AppBar(
              title: Text(title),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(
                  _getPlatformBackIcon(),
                  color: colorScheme.onSurface,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: mediaQuery.size.height - 
                (showBackButton ? kToolbarHeight : 0) -
                (useSafeArea ? mediaQuery.padding.top + mediaQuery.padding.bottom : 0),
          ),
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App branding section
                _buildBrandingSection(theme),
                const SizedBox(height: 32),
                
                // Title section (if no app bar)
                if (!showBackButton) ...[
                  Text(
                    title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                ],
                
                // Main content
                child,
                
                // Bottom spacing for keyboard
                SizedBox(height: mediaQuery.viewInsets.bottom > 0 ? 16 : 32),
              ],
            ),
          ),
        ),
      ),
    );

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return content;
  }

  Widget _buildBrandingSection(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    
    return Column(
      children: [
        // App icon/logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.account_balance_wallet,
            size: 40,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 16),
        
        // App name
        Text(
          'Expense Tracker',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  IconData _getPlatformBackIcon() {
    if (kIsWeb) return Icons.arrow_back;
    
    return Platform.isIOS 
        ? Icons.arrow_back_ios
        : Icons.arrow_back;
  }
}

/// Loading overlay widget for authentication screens
class AuthLoadingOverlay extends StatelessWidget {
  const AuthLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingMessage = 'Please wait...',
  });

  final bool isLoading;
  final Widget child;
  final String loadingMessage;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        loadingMessage,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Error display widget for authentication screens
class AuthErrorDisplay extends StatelessWidget {
  const AuthErrorDisplay({
    super.key,
    required this.error,
    this.onRetry,
  });

  final String error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: colorScheme.onErrorContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Authentication Error',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onErrorContainer,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Try Again',
                style: TextStyle(
                  color: colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Success message display widget
class AuthSuccessDisplay extends StatelessWidget {
  const AuthSuccessDisplay({
    super.key,
    required this.message,
    this.onContinue,
  });

  final String message;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: colorScheme.onPrimaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Success',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          if (onContinue != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onContinue,
              child: Text(
                'Continue',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Platform-aware button widget for authentication actions
class AuthActionButton extends StatelessWidget {
  const AuthActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.variant = AuthButtonVariant.primary,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final AuthButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final buttonStyle = switch (variant) {
      AuthButtonVariant.primary => ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      AuthButtonVariant.secondary => OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: colorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      AuthButtonVariant.text => TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
    };

    final button = switch (variant) {
      AuthButtonVariant.primary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.onPrimary,
                    ),
                  ),
                )
              : child,
        ),
      AuthButtonVariant.secondary => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: child,
        ),
      AuthButtonVariant.text => TextButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: child,
        ),
    };

    return SizedBox(
      width: double.infinity,
      child: button,
    );
  }
}

enum AuthButtonVariant {
  primary,
  secondary,
  text,
}