import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_providers.dart';
import '../../../../core/routing/app_router.dart';
import '../widgets/auth_screen_base.dart';
import '../widgets/auth_form_field.dart';

/// Password reset screen for recovering forgotten passwords
class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  late FocusNode _emailFocusNode;
  
  bool _emailSent = false;
  DateTime? _lastEmailSent;

  @override
  void initState() {
    super.initState();
    _emailFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authenticationProvider);
    
    return AuthScreenBase(
      title: 'Reset Password',
      showBackButton: true,
      child: AuthLoadingOverlay(
        isLoading: authState.isLoading,
        loadingMessage: 'Sending reset email...',
        child: _emailSent ? _buildSuccessView() : _buildFormView(authState),
      ),
    );
  }

  Widget _buildFormView(AsyncValue<AuthenticationState> authState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Reset password icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_reset,
              size: 40,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Title
          Text(
            'Forgot Your Password?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Email field
          AuthFormField(
            controller: _emailController,
            label: 'Email Address',
            hintText: 'Enter your email address',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.email_outlined,
            validator: EmailValidator.validate,
            autofocus: true,
            onFieldSubmitted: (_) => _handlePasswordReset(),
          ),
          
          const SizedBox(height: 24),
          
          // Error display
          authState.when(
            data: (state) => state.error != null
                ? Column(
                    children: [
                      AuthErrorDisplay(
                        error: state.error!,
                        onRetry: _handlePasswordReset,
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
                  onRetry: _handlePasswordReset,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          // Send reset email button
          AuthActionButton(
            onPressed: _canSendEmail() ? _handlePasswordReset : null,
            isLoading: authState.isLoading,
            child: Text(
              _getButtonText(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          if (!_canSendEmail()) ...[
            const SizedBox(height: 8),
            Text(
              'Please wait ${_getRemainingCooldown()} seconds before sending another email.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Back to sign in
          AuthActionButton(
            onPressed: () => AuthNavigation.toLogin(context),
            variant: AuthButtonVariant.text,
            child: const Text(
              'Back to Sign In',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_outline,
            size: 40,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Title
        Text(
          'Reset Email Sent',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16),
        
        // Description
        Text(
          'We\'ve sent a password reset link to:',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        // Email address
        Text(
          _emailController.text.trim(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 24),
        
        // Instructions card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Next Steps',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('1. Check your email inbox'),
                const SizedBox(height: 4),
                const Text('2. Click the password reset link'),
                const SizedBox(height: 4),
                const Text('3. Create a new password'),
                const SizedBox(height: 4),
                const Text('4. Sign in with your new password'),
                const SizedBox(height: 12),
                Text(
                  'The reset link will expire in 1 hour for security.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Don\'t see the email? Check your spam folder.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Resend email button
        AuthActionButton(
          onPressed: _canSendEmail() ? () {
            setState(() {
              _emailSent = false;
            });
            _handlePasswordReset();
          } : null,
          variant: AuthButtonVariant.secondary,
          child: Text(
            _canSendEmail() ? 'Resend Email' : 'Resend in ${_getRemainingCooldown()}s',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Back to login
        AuthActionButton(
          onPressed: () => AuthNavigation.toLogin(context),
          variant: AuthButtonVariant.text,
          child: const Text(
            'Back to Sign In',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _handlePasswordReset() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Clear focus from text fields
    FocusScope.of(context).unfocus();

    // Record when email was sent
    setState(() {
      _lastEmailSent = DateTime.now();
    });

    // Trigger password reset
    ref.read(authenticationProvider.notifier)
        .resetPasswordForEmail(_emailController.text.trim())
        .then((_) {
      // Check if the operation was successful by looking at the state
      final currentState = ref.read(authenticationProvider);
      currentState.whenData((state) {
        if (state.error == null) {
          setState(() {
            _emailSent = true;
          });
        }
      });
    });
  }

  bool _canSendEmail() {
    if (_lastEmailSent == null) return true;
    
    const cooldownDuration = Duration(seconds: 30);
    final timeSinceLastEmail = DateTime.now().difference(_lastEmailSent!);
    
    return timeSinceLastEmail >= cooldownDuration;
  }

  int _getRemainingCooldown() {
    if (_lastEmailSent == null) return 0;
    
    const cooldownDuration = Duration(seconds: 30);
    final timeSinceLastEmail = DateTime.now().difference(_lastEmailSent!);
    final remaining = cooldownDuration - timeSinceLastEmail;
    
    return remaining.inSeconds.clamp(0, 30);
  }

  String _getButtonText() {
    if (_canSendEmail()) {
      return 'Send Reset Email';
    } else {
      return 'Resend in ${_getRemainingCooldown()}s';
    }
  }
}

/// Password reset success screen (for deep link handling)
class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScreenBase(
      title: 'Password Reset',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 40,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Title
          Text(
            'Password Reset Complete',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            'Your password has been successfully updated. You can now sign in with your new password.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Success message card
          const AuthSuccessDisplay(
            message: 'Password successfully updated! You can now sign in with your new credentials.',
          ),
          
          const SizedBox(height: 24),
          
          // Continue to sign in
          AuthActionButton(
            onPressed: () => AuthNavigation.toLogin(context),
            child: const Text(
              'Continue to Sign In',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}