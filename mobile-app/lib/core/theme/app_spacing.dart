import 'package:flutter/material.dart';

/// Spacing, radius and elevation tokens.
///
/// Every gap in the app is a multiple of 4. Before this existed, padding values
/// were picked ad hoc per screen (8, 10, 12, 16, 20, 24, 28, 32 all appeared),
/// which is the main reason the old UI read as slightly-off rather than wrong.
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  /// Standard horizontal inset for screen content.
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: lg);

  /// Screen padding including a comfortable top gap.
  static const EdgeInsets screenPaddingAll = EdgeInsets.all(lg);

  /// Bottom padding for scroll views that sit beneath a pinned action bar, so
  /// the last item is never trapped under it.
  static const EdgeInsets bottomBarSafeArea = EdgeInsets.only(bottom: 120);

  /// Vertical gap helpers — `const AppGap.md()` reads better in a children list
  /// than a bare `SizedBox(height: 12)`.
  static const SizedBox gapXxs = SizedBox(height: xxs);
  static const SizedBox gapXs = SizedBox(height: xs);
  static const SizedBox gapSm = SizedBox(height: sm);
  static const SizedBox gapMd = SizedBox(height: md);
  static const SizedBox gapLg = SizedBox(height: lg);
  static const SizedBox gapXl = SizedBox(height: xl);
  static const SizedBox gapXxl = SizedBox(height: xxl);
  static const SizedBox gapXxxl = SizedBox(height: xxxl);
  static const SizedBox gapHuge = SizedBox(height: huge);

  static const SizedBox hGapXs = SizedBox(width: xs);
  static const SizedBox hGapSm = SizedBox(width: sm);
  static const SizedBox hGapMd = SizedBox(width: md);
  static const SizedBox hGapLg = SizedBox(width: lg);
}

/// Corner radii. Cards and sheets are noticeably rounded; inputs and chips a
/// little less, so controls do not read as pill-shaped unless they are.
class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));

  /// Bottom sheets and the venue-detail content panel: rounded on top only.
  static const BorderRadius topXl = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}

/// Animation durations, kept in one place so motion feels consistent rather
/// than each screen inventing its own timing.
class AppDurations {
  const AppDurations._();

  /// Taps, selection changes, colour transitions.
  static const Duration fast = Duration(milliseconds: 150);

  /// The default for most state changes.
  static const Duration normal = Duration(milliseconds: 250);

  /// Page transitions and larger reveals.
  static const Duration slow = Duration(milliseconds: 400);

  /// Splash logo entrance.
  static const Duration splash = Duration(milliseconds: 700);
}
