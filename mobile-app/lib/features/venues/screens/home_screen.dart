import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../models/venue_model.dart';
import '../../auth/providers/user_provider.dart';
import '../providers/venue_provider.dart';
import '../widgets/venue_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  double? _minPrice;
  double? _maxPrice;
  final Set<String> _selectedAmenities = <String>{};

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
    _debounce = Timer(const Duration(milliseconds: 400), _performSearch);
  }

  void _performSearch() {
    if (!mounted) return;
    context.read<VenueProvider>().searchVenues(
          query: _searchController.text.trim(),
          minPrice: _minPrice,
          maxPrice: _maxPrice,
          amenities: _selectedAmenities.toList(),
        );
  }

  Future<void> _showFilterSheet() async {
    // Edited on a copy so dismissing the sheet does not apply half-set filters.
    double? minPrice = _minPrice;
    double? maxPrice = _maxPrice;
    final Set<String> amenities = <String>{..._selectedAmenities};

    final bool? applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const Text(r'Price range ($/hr)'),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          initialValue: minPrice?.toStringAsFixed(0),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Min'),
                          onChanged: (String value) =>
                              minPrice = double.tryParse(value),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          initialValue: maxPrice?.toStringAsFixed(0),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Max'),
                          onChanged: (String value) =>
                              maxPrice = double.tryParse(value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Amenities'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _amenityOptions.map((String amenity) {
                      return FilterChip(
                        label: Text(amenity),
                        selected: amenities.contains(amenity),
                        onSelected: (bool selected) {
                          setSheetState(() {
                            if (selected) {
                              amenities.add(amenity);
                            } else {
                              amenities.remove(amenity);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: <Widget>[
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            minPrice = null;
                            maxPrice = null;
                            amenities.clear();
                          });
                        },
                        child: const Text('Clear'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                        child: const Text('Apply filters'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (applied != true || !mounted) return;
    setState(() {
      _minPrice = minPrice;
      _maxPrice = maxPrice;
      _selectedAmenities
        ..clear()
        ..addAll(amenities);
    });
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final UserProvider userProvider = context.watch<UserProvider>();
    final VenueProvider venueProvider = context.watch<VenueProvider>();
    final bool hasFilters = _minPrice != null ||
        _maxPrice != null ||
        _selectedAmenities.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Turf War'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'My bookings',
            onPressed: () => context.goNamed(AppRoutes.myBookings),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => context.goNamed(AppRoutes.profile),
          ),
        ],
      ),
      floatingActionButton: (userProvider.user?.canManageVenues ?? false)
          ? FloatingActionButton(
              onPressed: () => context.goNamed(AppRoutes.addVenue),
              tooltip: 'Add venue',
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Welcome, ${userProvider.user?.name ?? 'there'}',
                  style: theme.textTheme.headlineSmall,
                ),
                Text(
                  'Find your turf',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onChanged: _onSearchChanged,
                        onSubmitted: (_) => _performSearch(),
                        decoration: InputDecoration(
                          hintText: 'Search venues…',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _performSearch();
                                  },
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Badge(
                        isLabelVisible: hasFilters,
                        child: const Icon(Icons.tune),
                      ),
                      tooltip: 'Filters',
                      onPressed: _showFilterSheet,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(venueProvider)),
        ],
      ),
    );
  }

  Widget _buildBody(VenueProvider provider) {
    if (provider.isLoading && provider.venues.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.hasError) {
      return ErrorState(
        message: provider.error!,
        onRetry: () => context.read<VenueProvider>().fetchVenues(),
      );
    }

    if (provider.venues.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'No venues found',
        message: 'Try a different search or clear your filters.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<VenueProvider>().fetchVenues(),
      child: ListView.builder(
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
}

const List<String> _amenityOptions = <String>[
  'Wifi',
  'Parking',
  'Showers',
  'Lockers',
  'Water',
  'Floodlights',
];
