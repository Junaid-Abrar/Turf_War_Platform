import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../providers/user_provider.dart';
import '../widgets/demo_credentials_sheet.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    // Dismisses the keyboard so the result (a snackbar, or the home screen) is
    // not hidden behind it.
    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);
    try {
      await context.read<UserProvider>().login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      // No explicit navigation: the router's redirect reacts to the auth status
      // change and swaps in the home route.
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Fills the form from the demo account picker and signs straight in.
  ///
  /// This exists for the hosted demo: a recruiter opening the app should not
  /// have to type an email and password copied out of a README to see anything.
  Future<void> _pickDemoAccount() async {
    final DemoAccount? account = await showDemoCredentialsSheet(context);
    if (account == null || !mounted) return;

    _emailController.text = account.email;
    _passwordController.text = account.password;
    await _login();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              // Keeps the form a sensible width on a tablet or the web build
              // rather than stretching inputs edge to edge.
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Center(child: TurfWarLogo(size: 72)),
                      AppSpacing.gapLg,
                      Text(
                        'TURF WAR',
                        textAlign: TextAlign.center,
                        style: AppTypography.wordmark.copyWith(
                          fontSize: 26,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      AppSpacing.gapSm,
                      Text(
                        'Welcome back. Sign in to book your next slot.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.gapXxxl,
                      AppTextField(
                        controller: _emailController,
                        label: 'Email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const <String>[AutofillHints.email],
                        enabled: !_isSubmitting,
                        validator: _validateEmail,
                      ),
                      AppSpacing.gapLg,
                      AppTextField(
                        controller: _passwordController,
                        label: 'Password',
                        prefixIcon: Icons.lock_outline,
                        obscure: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const <String>[AutofillHints.password],
                        enabled: !_isSubmitting,
                        onSubmitted: (_) => _login(),
                        validator: (String? value) =>
                            (value == null || value.isEmpty)
                                ? 'Enter your password'
                                : null,
                      ),
                      AppSpacing.gapXxl,
                      AppButton(
                        label: 'Log in',
                        expand: true,
                        isLoading: _isSubmitting,
                        onPressed: _login,
                      ),
                      AppSpacing.gapMd,
                      AppButton(
                        label: 'Use a demo account',
                        icon: Icons.bolt_outlined,
                        variant: AppButtonVariant.secondary,
                        expand: true,
                        onPressed: _isSubmitting ? null : _pickDemoAccount,
                      ),
                      AppSpacing.gapLg,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'New here?',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => context.goNamed(AppRoutes.register),
                            child: const Text('Create an account'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Mirrors the backend's express-validator `isEmail` check closely enough to
  /// catch typos before a round trip, without trying to be RFC-complete.
  String? _validateEmail(String? value) {
    final String email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email address';
    }
    return null;
  }
}
