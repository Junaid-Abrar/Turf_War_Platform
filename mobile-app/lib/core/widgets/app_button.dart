import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Visual weight of an [AppButton].
enum AppButtonVariant {
  /// Filled with the brand colour — the single primary action on a screen.
  primary,

  /// Outlined — secondary actions sitting beside a primary one.
  secondary,

  /// Text only — tertiary actions, and anything in a dialog's action row.
  ghost,

  /// Filled with the danger colour — cancel, delete, log out.
  danger,
}

/// The app's button.
///
/// Exists mainly for one behaviour that was previously copy-pasted into six
/// screens: while [isLoading] the label is swapped for a spinner **at the same
/// size**, so the button does not resize mid-request and shift the layout under
/// the user's finger. It also centralises the "loading implies disabled" rule,
/// which two of those copies got wrong.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  /// Stretches to the available width. Off by default so the button sizes to
  /// its label in a row.
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    // A loading button must not be tappable: without this, a double tap fires
    // two bookings.
    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;

    final Widget child = _buildChild(context);

    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: effectiveOnPressed,
          child: child,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: effectiveOnPressed,
          child: child,
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: effectiveOnPressed,
          child: child,
        ),
      AppButtonVariant.danger => FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colors.errorContainer,
            foregroundColor: colors.onErrorContainer,
          ),
          child: child,
        ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      // Sized to roughly the label's cap height so the button keeps its
      // intrinsic height and the row around it does not reflow.
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: _foregroundFor(context),
        ),
      );
    }

    if (icon == null) return Text(label);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 18),
        AppSpacing.hGapSm,
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  /// The spinner has to be tinted to match the button's own foreground, or it
  /// renders in the default primary colour and disappears on a filled button.
  ///
  /// A loading button is also a *disabled* button, so Material paints it with
  /// the disabled container colour rather than the variant's own. Tinting the
  /// spinner `onPrimary` in that state leaves it nearly invisible against the
  /// grey — `onSurfaceVariant` is what actually reads on every variant.
  Color _foregroundFor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}
