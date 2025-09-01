import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable form field widget for authentication screens
/// Provides consistent styling, validation, and accessibility features
class AuthFormField extends StatefulWidget {
  const AuthFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.validator,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.showToggleVisibility = false,
    this.prefixIcon,
    this.enabled = true,
    this.autofocus = false,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.maxLength,
    this.helpText,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;
  final String? hintText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final bool showToggleVisibility;
  final IconData? prefixIcon;
  final bool enabled;
  final bool autofocus;
  final void Function(String)? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final String? helpText;

  @override
  State<AuthFormField> createState() => _AuthFormFieldState();
}

class _AuthFormFieldState extends State<AuthFormField> {
  bool _isObscured = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: _isObscured,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          onFieldSubmitted: widget.onFieldSubmitted,
          inputFormatters: widget.inputFormatters,
          maxLength: widget.maxLength,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon != null 
                ? Icon(widget.prefixIcon, size: 20)
                : null,
            suffixIcon: widget.showToggleVisibility
                ? IconButton(
                    icon: Icon(
                      _isObscured ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscured = !_isObscured;
                      });
                    },
                    tooltip: _isObscured ? 'Show password' : 'Hide password',
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.error,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: widget.enabled 
                ? colorScheme.surface
                : colorScheme.surfaceContainerHighest.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: widget.enabled 
                ? colorScheme.onSurface
                : colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        if (widget.helpText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.helpText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Password strength indicator widget
class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showDetails = false,
  });

  final String password;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final strength = _calculatePasswordStrength(password);
    final strengthInfo = _getStrengthInfo(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: strength / 4,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  strengthInfo.color,
                ),
                minHeight: 4,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              strengthInfo.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: strengthInfo.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (showDetails && password.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildRequirementsList(theme, colorScheme),
        ],
      ],
    );
  }

  Widget _buildRequirementsList(ThemeData theme, ColorScheme colorScheme) {
    final requirements = [
      _RequirementCheck(
        'At least 8 characters',
        password.length >= 8,
      ),
      _RequirementCheck(
        'Contains uppercase letter',
        password.contains(RegExp(r'[A-Z]')),
      ),
      _RequirementCheck(
        'Contains lowercase letter',
        password.contains(RegExp(r'[a-z]')),
      ),
      _RequirementCheck(
        'Contains number',
        password.contains(RegExp(r'[0-9]')),
      ),
      _RequirementCheck(
        'Contains special character',
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
      ),
    ];

    return Column(
      children: requirements.map((req) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(
                req.isMet ? Icons.check : Icons.close,
                size: 16,
                color: req.isMet 
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                req.text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: req.isMet 
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    
    int strength = 0;
    
    // Length check
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    
    // Character type checks
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    
    // Reduce strength for common patterns
    if (password.toLowerCase().contains('password') ||
        password.toLowerCase().contains('123456') ||
        password == '12345678') {
      strength = (strength / 2).floor();
    }
    
    return strength.clamp(0, 4);
  }

  _StrengthInfo _getStrengthInfo(int strength) {
    switch (strength) {
      case 0:
        return const _StrengthInfo('Very Weak', Colors.red);
      case 1:
        return const _StrengthInfo('Weak', Colors.orange);
      case 2:
        return const _StrengthInfo('Fair', Colors.yellow);
      case 3:
        return const _StrengthInfo('Good', Colors.lightGreen);
      case 4:
        return const _StrengthInfo('Strong', Colors.green);
      default:
        return const _StrengthInfo('Very Weak', Colors.red);
    }
  }
}

class _StrengthInfo {
  final String label;
  final Color color;

  const _StrengthInfo(this.label, this.color);
}

class _RequirementCheck {
  final String text;
  final bool isMet;

  const _RequirementCheck(this.text, this.isMet);
}

/// Email validation utility
class EmailValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
}

/// Password validation utility
class PasswordValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain uppercase letter';
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain lowercase letter';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }
    
    return null;
  }

  static String? validateConfirmation(String? value, String originalPassword) {
    final baseValidation = validate(value);
    if (baseValidation != null) return baseValidation;
    
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    
    return null;
  }
}