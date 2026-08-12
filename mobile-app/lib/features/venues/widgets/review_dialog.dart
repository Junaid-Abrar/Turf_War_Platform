import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';

/// What the user typed into the review dialog.
@immutable
class ReviewDraft {
  final double rating;
  final String comment;

  const ReviewDraft({required this.rating, required this.comment});
}

/// Collects a rating and a comment.
///
/// Returns the draft, or null if the dialog was dismissed. The controller is
/// owned by the dialog's own [State] so it is disposed exactly once — the
/// previous inline version created it in the calling screen and had to dispose
/// it manually on three separate return paths.
Future<ReviewDraft?> showReviewDialog(BuildContext context) {
  return showDialog<ReviewDraft>(
    context: context,
    builder: (BuildContext dialogContext) => const _ReviewDialog(),
  );
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog();

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final TextEditingController _commentController = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Rate this venue'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Tappable stars rather than the dropdown this used to be: one tap
          // instead of open-scroll-select, and the rating is visible without
          // opening anything.
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int star = 1; star <= 5; star++)
                  IconButton(
                    onPressed: () => setState(() => _rating = star),
                    tooltip: '$star ${star == 1 ? 'star' : 'stars'}',
                    icon: Icon(
                      star <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 32,
                      color: star <= _rating
                          ? context.semanticColors.rating
                          : theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
          AppSpacing.gapSm,
          Center(
            child: Text(
              _ratingLabel(_rating),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          AppSpacing.gapLg,
          AppTextField(
            controller: _commentController,
            label: 'Comment',
            hint: 'How was the pitch?',
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            ReviewDraft(
              rating: _rating.toDouble(),
              comment: _commentController.text.trim(),
            ),
          ),
          child: const Text('Post review'),
        ),
      ],
    );
  }

  String _ratingLabel(int rating) {
    return switch (rating) {
      1 => 'Poor',
      2 => 'Below average',
      3 => 'Decent',
      4 => 'Good',
      _ => 'Excellent',
    };
  }
}
