import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_providers.dart';
import '../../../../core/routing/app_router.dart';
import '../widgets/auth_screen_base.dart';
import '../widgets/auth_form_field.dart';

/// Sign up screen for creating new accounts with email/password
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  
  late FocusNode _emailFocusNode;
  late FocusNode _passwordFocusNode;
  late FocusNode _confirmPasswordFocusNode;
  late FocusNode _displayNameFocusNode;

  bool _acceptTerms = false;
  bool _showPasswordStrength = false;

  @override
  void initState() {
    super.initState();
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    _confirmPasswordFocusNode = FocusNode();
    _displayNameFocusNode = FocusNode();
    
    // Show password strength when user starts typing
    _passwordController.addListener(() {
      final shouldShow = _passwordController.text.isNotEmpty;
      if (_showPasswordStrength != shouldShow) {
        setState(() {
          _showPasswordStrength = shouldShow;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _displayNameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authenticationProvider);
    
    return AuthScreenBase(
      title: 'Create Account',
      showBackButton: true,
      child: AuthLoadingOverlay(
        isLoading: authState.isLoading,
        loadingMessage: 'Creating your account...',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Display name field (optional)
              AuthFormField(
                controller: _displayNameController,
                label: 'Display Name (Optional)',
                hintText: 'How should we call you?',
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  // Optional field, no validation required
                  return null;
                },
                onFieldSubmitted: (_) {
                  _emailFocusNode.requestFocus();
                },
                helpText: 'This will be shown in the app',
              ),
              
              const SizedBox(height: 16),
              
              // Email field
              AuthFormField(
                controller: _emailController,
                label: 'Email Address',
                hintText: 'Enter your email address',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.email_outlined,
                validator: EmailValidator.validate,
                onFieldSubmitted: (_) {
                  _passwordFocusNode.requestFocus();
                },
              ),
              
              const SizedBox(height: 16),
              
              // Password field
              AuthFormField(
                controller: _passwordController,
                label: 'Password',
                hintText: 'Create a strong password',
                obscureText: true,
                showToggleVisibility: true,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.lock_outlined,
                validator: PasswordValidator.validate,
                onFieldSubmitted: (_) {
                  _confirmPasswordFocusNode.requestFocus();
                },
              ),
              
              // Password strength indicator
              if (_showPasswordStrength) ...[
                const SizedBox(height: 8),
                PasswordStrengthIndicator(
                  password: _passwordController.text,
                  showDetails: true,
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Confirm password field
              AuthFormField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hintText: 'Re-enter your password',
                obscureText: true,
                showToggleVisibility: true,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.lock_outline,
                validator: (value) => PasswordValidator.validateConfirmation(
                  value,
                  _passwordController.text,
                ),
                onFieldSubmitted: (_) => _handleSignUp(),
              ),
              
              const SizedBox(height: 24),
              
              // Terms and conditions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _acceptTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptTerms = value ?? false;
                      });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _acceptTerms = !_acceptTerms;
                        });
                      },
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Error display
              authState.when(
                data: (state) => state.error != null
                    ? Column(
                        children: [
                          AuthErrorDisplay(
                            error: state.error!,
                            onRetry: _handleSignUp,
                          ),
                          const SizedBox(height: 16),
                        ],
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (error, _) => Column(
                  children: [
                    AuthErrorDisplay(
                      error: error.toString(),
                      onRetry: _handleSignUp,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              
              // Create account button
              AuthActionButton(
                onPressed: _acceptTerms ? _handleSignUp : null,
                isLoading: authState.isLoading,
                child: const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Already have account link
              AuthActionButton(
                onPressed: () => AuthNavigation.toLogin(context),
                variant: AuthButtonVariant.secondary,
                child: const Text(
                  'Already have an account? Sign In',
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

  void _handleSignUp() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please accept the Terms of Service and Privacy Policy'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Clear focus from text fields
    FocusScope.of(context).unfocus();

    // Get display name, use email prefix as fallback
    final displayName = _displayNameController.text.trim().isNotEmpty
        ? _displayNameController.text.trim()
        : _emailController.text.trim().split('@').first;

    // Trigger sign up
    ref.read(authenticationProvider.notifier).signUpWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: displayName,
        );
  }
}

/// Terms of Service modal dialog
class TermsOfServiceDialog extends StatelessWidget {
  const TermsOfServiceDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Terms of Service'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last updated: ${DateTime.now().year}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Acceptance of Terms\n\n'
                'By using the Expense Tracker app, you agree to these terms and conditions.\n\n'
                '2. Description of Service\n\n'
                'Expense Tracker helps you manage your personal finances by tracking expenses, budgets, and financial goals.\n\n'
                '3. User Accounts\n\n'
                'You are responsible for maintaining the confidentiality of your account and password.\n\n'
                '4. Privacy and Data\n\n'
                'We take your privacy seriously. Your financial data is encrypted and never shared with third parties.\n\n'
                '5. Prohibited Uses\n\n'
                'You may not use this service for any illegal or unauthorized purpose.\n\n'
                '6. Changes to Terms\n\n'
                'We reserve the right to update these terms at any time. Continued use constitutes acceptance of new terms.\n\n'
                '7. Contact Information\n\n'
                'For questions about these terms, please contact our support team.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Privacy Policy modal dialog
class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Privacy Policy'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last updated: ${DateTime.now().year}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Information We Collect\n\n'
                'We collect information you provide directly, such as account information and financial data you enter.\n\n'
                '2. How We Use Information\n\n'
                '• To provide and maintain our service\n'
                '• To notify you about changes to our service\n'
                '• To provide customer support\n\n'
                '3. Information Security\n\n'
                'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.\n\n'
                '4. Data Retention\n\n'
                'We retain your personal information only as long as necessary to provide you with our service and fulfill the purposes outlined in this policy.\n\n'
                '5. Third-Party Services\n\n'
                'We may use third-party services for authentication and data storage. These services have their own privacy policies.\n\n'
                '6. Your Rights\n\n'
                'You have the right to access, update, or delete your personal information at any time.\n\n'
                '7. Contact Us\n\n'
                'If you have any questions about this privacy policy, please contact our support team.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}