import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_screen.dart';
import 'sign_up_screen.dart';
import 'password_reset_screen.dart';

/// Main authentication screen that provides navigation between auth flows
class AuthMainScreen extends ConsumerStatefulWidget {
  const AuthMainScreen({super.key});

  @override
  ConsumerState<AuthMainScreen> createState() => _AuthMainScreenState();
}

class _AuthMainScreenState extends ConsumerState<AuthMainScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          // Login Screen
          _AuthPageWrapper(
            showSignUpOption: true,
            showPasswordResetOption: true,
            onNavigateToSignUp: () => _navigateToPage(1),
            onNavigateToPasswordReset: () => _navigateToPage(2),
            child: const LoginScreen(),
          ),
          
          // Sign Up Screen  
          _AuthPageWrapper(
            showLoginOption: true,
            onNavigateToLogin: () => _navigateToPage(0),
            child: const SignUpScreen(),
          ),
          
          // Password Reset Screen
          _AuthPageWrapper(
            showLoginOption: true,
            onNavigateToLogin: () => _navigateToPage(0),
            child: const PasswordResetScreen(),
          ),
        ],
      ),
    );
  }
}

/// Wrapper for auth pages to provide consistent navigation options
class _AuthPageWrapper extends StatelessWidget {
  const _AuthPageWrapper({
    required this.child,
    this.showSignUpOption = false,
    this.showLoginOption = false,
    this.showPasswordResetOption = false,
    this.onNavigateToSignUp,
    this.onNavigateToLogin,
    this.onNavigateToPasswordReset,
  });

  final Widget child;
  final bool showSignUpOption;
  final bool showLoginOption;
  final bool showPasswordResetOption;
  final VoidCallback? onNavigateToSignUp;
  final VoidCallback? onNavigateToLogin;
  final VoidCallback? onNavigateToPasswordReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: child),
        
        // Navigation options
        if (showSignUpOption || showLoginOption || showPasswordResetOption)
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (showSignUpOption) ...[
                  TextButton(
                    onPressed: onNavigateToSignUp,
                    child: const Text("Don't have an account? Sign Up"),
                  ),
                  const SizedBox(height: 8),
                ],
                
                if (showPasswordResetOption) ...[
                  TextButton(
                    onPressed: onNavigateToPasswordReset,
                    child: const Text('Forgot Password?'),
                  ),
                  const SizedBox(height: 8),
                ],
                
                if (showLoginOption) ...[
                  TextButton(
                    onPressed: onNavigateToLogin,
                    child: const Text('Already have an account? Sign In'),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}