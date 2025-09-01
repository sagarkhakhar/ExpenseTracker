import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_providers.dart';
import '../../../../core/routing/app_router.dart';
import '../widgets/auth_screen_base.dart';
import '../widgets/auth_form_field.dart';

/// Login screen for email/password authentication
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  late FocusNode _emailFocusNode;
  late FocusNode _passwordFocusNode;

  @override
  void initState() {
    super.initState();
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authenticationProvider);
    
    return AuthScreenBase(
      title: 'Sign In',
      child: AuthLoadingOverlay(
        isLoading: authState.isLoading,
        loadingMessage: 'Signing in...',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Email field
              AuthFormField(
                controller: _emailController,
                label: 'Email',
                hintText: 'Enter your email address',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.email_outlined,
                validator: EmailValidator.validate,
                autofocus: true,
                onFieldSubmitted: (_) {
                  _passwordFocusNode.requestFocus();
                },
              ),
              
              const SizedBox(height: 16),
              
              // Password field
              AuthFormField(
                controller: _passwordController,
                label: 'Password',
                hintText: 'Enter your password',
                obscureText: true,
                showToggleVisibility: true,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.lock_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _handleSignIn(),
              ),
              
              const SizedBox(height: 8),
              
              // Forgot password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => AuthNavigation.toPasswordReset(context),
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Error display
              authState.when(
                data: (state) => state.error != null
                    ? Column(
                        children: [
                          AuthErrorDisplay(
                            error: state.error!,
                            onRetry: _handleSignIn,
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
                      onRetry: _handleSignIn,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              
              // Sign in button
              AuthActionButton(
                onPressed: _handleSignIn,
                isLoading: authState.isLoading,
                child: const Text(
                  'Sign In',
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
              
              // Sign up link
              AuthActionButton(
                onPressed: () => AuthNavigation.toSignUp(context),
                variant: AuthButtonVariant.secondary,
                child: const Text(
                  'Don\'t have an account? Sign Up',
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

  void _handleSignIn() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Clear focus from text fields
    FocusScope.of(context).unfocus();

    // Trigger sign in
    ref.read(authenticationProvider.notifier).signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

}