import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/venue_model.dart';
import '../../auth/providers/user_provider.dart';
import '../providers/venue_provider.dart';
import '../widgets/sport_category_row.dart';
import '../widgets/venue_card.dart';
import '../widgets/venue_filter_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  VenueFilters _filters = const VenueFilters();
  SportCategory _category = SportCategory.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VenueProvider>().fetchVenues();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Waits for a pause in typing so a search is not fired per keystroke.
  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      // Redraws the clear button, which appears only once there is text.
      if (mounted) setState(() {});
      _performSearch();
    });
  }

  void _performSearch() {
    if (!mounted) return;

    // The backend has no sport field, so a category narrows the same free-text
    // query the search box uses. Combining them keeps one request rather than
    // filtering the result set client-side, which would break with pagination.
    final String typed = _searchController.text.trim();
    final String query = <String>[
      if (typed.isNotEmpty) typed,
      if (_category != SportCategory.all) _category.searchTerm,
    ].join(' ');

    context.read<VenueProvider>().searchVenues(
          query: query,
          minPrice: _filters.minPrice,
          maxPrice: _filters.maxPrice,
          amenities: _filters.amenities.toList(),
        );
  }

  Future<void> _showFilterSheet() async {
    final VenueFilters? applied = await showVenueFilterSheet(context, _filters);
    if (applied == null || !mounted) return;
    setState(() => _filters = applied);
    _performSearch();
  }

  void _onCategorySelected(SportCategory category) {
    if (category == _category) return;
    setState(() => _category = category);
    _performSearch();
  }

  Future<void> _refresh() {
    // Pull-to-refresh re-runs the active query rather than resetting to the
    // full list, so a user who has filtered does not silently lose their
    // filters by pulling down.
    _performSearch();
    return Future<void>.value();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final UserProvider userProvider = context.watch<UserProvider>();
    final VenueProvider venueProvider = context.watch<VenueProvider>();

    return Scaffold(
      floatingActionButton: (userProvider.user?.canManageVenues ?? false)
          ? FloatingActionButton.extended(
              onPressed: () => context.goNamed(AppRoutes.addVenue),
              icon: const Icon(Icons.add),
              label: const Text('List a venue'),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _greeting(userProvider.user?.name),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              'Find your turf',
                              style: theme.textTheme.headlineMedium,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_month_outlined),
                        tooltip: 'My bookings',
                        onPressed: () => context.goNamed(AppRoutes.myBookings),
                      ),
                      _ProfileButton(
                        initial: userProvider.user?.initial ?? '?',
                        onPressed: () => context.goNamed(AppRoutes.profile),
                      ),
                    ],
                  ),
                  AppSpacing.gapLg,
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onChanged: _onSearchChanged,
                          onSubmitted: (_) => _performSearch(),
                          decoration: InputDecoration(
                            hintText: 'Search venues or locations',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            // Vertically compact so the search row does not
                            // dominate the header.
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    tooltip: 'Clear search',
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                      _performSearch();
                                    },
                                  ),
                          ),
                        ),
                      ),
                      AppSpacing.hGapSm,
                      _FilterButton(
                        activeCount: _filters.activeCount,
                        onPressed: _showFilterSheet,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppSpacing.gapLg,
            SportCategoryRow(
              selected: _category,
              onSelected: _onCategorySelected,
            ),
            if (_filters.hasAny)
              _ActiveFilterSummary(
                filters: _filters,
                onClear: () {
                  setState(() => _filters = const VenueFilters());
                  _performSearch();
                },
              ),
            AppSpacing.gapSm,
            Expanded(child: _buildBody(venueProvider)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(VenueProvider provider) {
    // Skeletons only for the very first load; a refresh keeps the existing list
    // on screen underneath the refresh indicator rather than blanking it.
    if (provider.isLoading && provider.venues.isEmpty) {
      return const VenueListSkeleton();
    }

    if (provider.hasError && provider.venues.isEmpty) {
      return ErrorState(
        message: provider.error!,
        onRetry: () => context.read<VenueProvider>().fetchVenues(),
      );
    }

    if (provider.venues.isEmpty) {
      final bool isFiltered = _filters.hasAny ||
          _category != SportCategory.all ||
          _searchController.text.trim().isNotEmpty;

      return EmptyState(
        icon: isFiltered ? Icons.search_off : Icons.stadium_outlined,
        title: isFiltered ? 'No matches' : 'No venues yet',
        message: isFiltered
            ? 'Nothing fits those filters. Try widening your search.'
            : 'Venues added by owners will show up here.',
        action: isFiltered
            ? AppButton(
                label: 'Clear filters',
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _filters = const VenueFilters();
                    _category = SportCategory.all;
                  });
                  _performSearch();
                },
              )
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          // Clears the extended FAB so the last card is fully reachable.
          96,
        ),
        itemCount: provider.venues.length,
        itemBuilder: (BuildContext context, int index) {
          final VenueModel venue = provider.venues[index];
          return VenueCard(
            venue: venue,
            onTap: () => context.goNamed(
              AppRoutes.venueDetails,
              pathParameters: <String, String>{'venueId': venue.id},
              // Hands the already-loaded venue to the detail screen so it can
              // render without a second request.
              extra: venue,
            ),
          );
        },
      ),
    );
  }

  String _greeting(String? name) {
    final int hour = DateTime.now().hour;
    final String partOfDay = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    // Only the first name — full names run long enough to wrap the header.
    final String firstName = (name ?? '').split(' ').first;
    return firstName.isEmpty ? partOfDay : '$partOfDay, $firstName';
  }
}

/// Avatar button opening the profile screen.
class _ProfileButton extends StatelessWidget {
  final String initial;
  final VoidCallback onPressed;

  const _ProfileButton({required this.initial, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: 'Profile',
      onPressed: onPressed,
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: colors.primaryContainer,
        child: Text(
          initial,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.onPrimaryContainer,
              ),
        ),
      ),
    );
  }
}

/// Filter button showing a count of the filters currently applied.
class _FilterButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onPressed;

  const _FilterButton({required this.activeCount, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isActive = activeCount > 0;

    return IconButton(
      tooltip: 'Filters',
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: isActive,
        label: Text('$activeCount'),
        child: const Icon(Icons.tune, size: 20),
      ),
      style: IconButton.styleFrom(
        backgroundColor:
            isActive ? colors.primaryContainer : colors.surfaceContainerLow,
        foregroundColor:
            isActive ? colors.onPrimaryContainer : colors.onSurfaceVariant,
        minimumSize: const Size(52, 52),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
    );
  }
}

/// A one-line summary of the active price/amenity filters with a clear action,
/// so applied filters are visible without reopening the sheet.
class _ActiveFilterSummary extends StatelessWidget {
  final VenueFilters filters;
  final VoidCallback onClear;

  const _ActiveFilterSummary({required this.filters, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        0,
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.filter_alt_outlined,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          AppSpacing.hGapXs,
          Expanded(
            child: Text(
              filters.summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(onPressed: onClear, child: const Text('Clear')),
        ],
      ),
    );
  }
}
