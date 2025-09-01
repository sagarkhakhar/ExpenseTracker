import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/views/login_screen.dart';
import '../../features/auth/presentation/views/sign_up_screen.dart';
import '../../features/auth/presentation/views/password_reset_screen.dart';
import '../../features/auth/presentation/views/email_verification_screen.dart';
import '../../features/expense/presentation/views/home_screen.dart';
import '../../features/expense/presentation/views/add_expense_screen.dart';
import '../providers/auth_providers.dart';

/// Simple app router that handles authentication-aware routing
class AppRouter {
  static const String home = '/';
  static const String authLogin = '/auth/login';
  static const String authSignUp = '/auth/sign-up';
  static const String authResetPassword = '/auth/reset-password';
  static const String authEmailVerification = '/auth/verify-email';
  static const String addExpense = '/add-expense';

  /// Generate routes based on authentication state
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case authLogin:
        return _buildRoute(const LoginScreen(), settings);
      
      case authSignUp:
        return _buildRoute(const SignUpScreen(), settings);
      
      case authResetPassword:
        return _buildRoute(const PasswordResetScreen(), settings);
      
      case authEmailVerification:
        return _buildRoute(const EmailVerificationScreen(), settings);
      
      case addExpense:
        return _buildRoute(const AddExpenseScreen(), settings);
      
      case home:
      default:
        // Home route is handled by AuthenticationGate
        return _buildRoute(const HomeScreen(), settings);
    }
  }

  /// Build platform-aware page route
  static PageRoute<T> _buildRoute<T>(Widget child, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, _) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Slide transition for authentication screens
        if (settings.name?.startsWith('/auth') == true) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          final tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        }

        // Fade transition for other screens
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}


/// Loading screen shown during authentication state initialization
class AuthenticationLoadingScreen extends StatelessWidget {
  const AuthenticationLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App branding
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.account_balance_wallet,
                size: 40,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // App name
            Text(
              'Expense Tracker',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Loading indicator
            const CircularProgressIndicator(),
            
            const SizedBox(height: 16),
            
            // Loading message
            Text(
              'Initializing...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen shown when authentication initialization fails
class AuthenticationErrorScreen extends StatelessWidget {
  const AuthenticationErrorScreen({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error icon
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              
              const SizedBox(height: 24),
              
              // Error title
              Text(
                'Authentication Error',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Error message
              Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Retry button
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Navigation helper for authentication screens
class AuthNavigation {
  /// Navigate to login screen
  static void toLogin(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.authLogin,
      (route) => false,
    );
  }

  /// Navigate to sign up screen
  static void toSignUp(BuildContext context) {
    Navigator.of(context).pushNamed(AppRouter.authSignUp);
  }

  /// Navigate to password reset screen
  static void toPasswordReset(BuildContext context) {
    Navigator.of(context).pushNamed(AppRouter.authResetPassword);
  }

  /// Navigate to home screen (after successful authentication)
  static void toHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.home,
      (route) => false,
    );
  }

  /// Navigate back to previous screen
  static void back(BuildContext context) {
    Navigator.of(context).pop();
  }
}