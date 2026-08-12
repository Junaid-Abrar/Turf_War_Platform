import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import 'amenity_icons.dart';

/// The filters applied to the venue list.
///
/// An immutable value rather than three loose fields on the screen's state:
/// the sheet edits a copy and returns it, so dismissing the sheet cannot leave
/// half-applied filters behind — the bug the old inline sheet worked around
/// with three shadow variables.
@immutable
class VenueFilters {
  final double? minPrice;
  final double? maxPrice;
  final Set<String> amenities;

  const VenueFilters({
    this.minPrice,
    this.maxPrice,
    this.amenities = const <String>{},
  });

  bool get hasAny =>
      minPrice != null || maxPrice != null || amenities.isNotEmpty;

  /// Number of distinct filters applied, shown on the filter button's badge.
  /// A price range counts once however many of its two bounds are set.
  int get activeCount =>
      ((minPrice != null || maxPrice != null) ? 1 : 0) + amenities.length;

  /// Human-readable summary for the active-filter strip.
  String get summary {
    final List<String> parts = <String>[];
    if (minPrice != null && maxPrice != null) {
      parts.add('\$${minPrice!.toStringAsFixed(0)}'
          '–\$${maxPrice!.toStringAsFixed(0)}/hr');
    } else if (minPrice != null) {
      parts.add('From \$${minPrice!.toStringAsFixed(0)}/hr');
    } else if (maxPrice != null) {
      parts.add('Up to \$${maxPrice!.toStringAsFixed(0)}/hr');
    }
    parts.addAll(amenities);
    return parts.join(' · ');
  }

  VenueFilters copyWith({
    double? minPrice,
    double? maxPrice,
    Set<String>? amenities,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
  }) {
    return VenueFilters(
      // Explicit clear flags: a null argument means "unchanged" in the copyWith
      // idiom, so there would otherwise be no way to unset a price.
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      amenities: amenities ?? this.amenities,
    );
  }
}

/// The price bounds offered by the slider. Anything above [_maxPriceBound] is
/// treated as "no upper limit" so the filter never hides expensive venues the
/// user did not mean to exclude.
const double _maxPriceBound = 200;

/// Opens the filter sheet. Returns the new filters, or null if dismissed.
Future<VenueFilters?> showVenueFilterSheet(
  BuildContext context,
  VenueFilters current,
) {
  return showModalBottomSheet<VenueFilters>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) =>
        _FilterSheet(initial: current),
  );
}

class _FilterSheet extends StatefulWidget {
  final VenueFilters initial;

  const _FilterSheet({required this.initial});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late RangeValues _priceRange = RangeValues(
    widget.initial.minPrice ?? 0,
    widget.initial.maxPrice ?? _maxPriceBound,
  );
  late Set<String> _amenities = <String>{...widget.initial.amenities};

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isFullRange =
        _priceRange.start == 0 && _priceRange.end == _maxPriceBound;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          0,
          AppSpacing.xxl,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text('Filters', style: theme.textTheme.headlineSmall),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _priceRange = const RangeValues(0, _maxPriceBound);
                    _amenities = <String>{};
                  }),
                  child: const Text('Reset'),
                ),
              ],
            ),
            AppSpacing.gapLg,
            Text('Price per hour', style: theme.textTheme.titleMedium),
            AppSpacing.gapXs,
            Text(
              isFullRange
                  ? 'Any price'
                  : '\$${_priceRange.start.toStringAsFixed(0)} – '
                      '\$${_priceRange.end.toStringAsFixed(0)}'
                      '${_priceRange.end >= _maxPriceBound ? '+' : ''}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            // A range slider rather than the two numeric text fields this used
            // to be: no keyboard, and min > max is unrepresentable.
            RangeSlider(
              values: _priceRange,
              max: _maxPriceBound,
              divisions: 20,
              labels: RangeLabels(
                '\$${_priceRange.start.toStringAsFixed(0)}',
                '\$${_priceRange.end.toStringAsFixed(0)}',
              ),
              onChanged: (RangeValues values) =>
                  setState(() => _priceRange = values),
            ),
            AppSpacing.gapLg,
            Text('Amenities', style: theme.textTheme.titleMedium),
            AppSpacing.gapMd,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                for (final String amenity in kAmenityOptions)
                  FilterChip(
                    label: Text(amenity),
                    avatar: Icon(iconForAmenity(amenity), size: 16),
                    selected: _amenities.contains(amenity),
                    showCheckmark: false,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _amenities.add(amenity);
                        } else {
                          _amenities.remove(amenity);
                        }
                      });
                    },
                  ),
              ],
            ),
            AppSpacing.gapXxl,
            AppButton(
              label: 'Show results',
              expand: true,
              onPressed: () => Navigator.of(context).pop(_buildFilters()),
            ),
          ],
        ),
      ),
    );
  }

  /// Converts the slider's full-range position back into "no filter", so an
  /// untouched slider does not send bounds the user never chose.
  VenueFilters _buildFilters() {
    return VenueFilters(
      minPrice: _priceRange.start > 0 ? _priceRange.start : null,
      maxPrice: _priceRange.end < _maxPriceBound ? _priceRange.end : null,
      amenities: _amenities,
    );
  }
}
