import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';

/// Swipeable gallery for a venue's photos, with page dots and a scrim.
///
/// Only the first image is wrapped in the [Hero] — a Hero animation needs
/// exactly one widget with a given tag on each route, so tagging every page
/// would throw the moment the carousel was swiped and two pages were alive at
/// once.
class VenueImageCarousel extends StatefulWidget {
  final List<String> images;
  final String heroTag;

  const VenueImageCarousel({
    super.key,
    required this.images,
    required this.heroTag,
  });

  @override
  State<VenueImageCarousel> createState() => _VenueImageCarouselState();
}

class _VenueImageCarouselState extends State<VenueImageCarousel> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A venue with no images still needs the Hero, or the flight from the card
    // has no landing target and the image snaps instead of animating.
    if (widget.images.isEmpty) {
      return Hero(
        tag: widget.heroTag,
        child: const AppNetworkImage(url: null, fallbackIconSize: 72),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        PageView.builder(
          controller: _controller,
          itemCount: widget.images.length,
          onPageChanged: (int page) => setState(() => _currentPage = page),
          itemBuilder: (BuildContext context, int index) {
            final Widget image = AppNetworkImage(
              url: widget.images[index],
              fit: BoxFit.cover,
              fallbackIconSize: 72,
            );
            return index == 0
                ? Hero(tag: widget.heroTag, child: image)
                : image;
          },
        ),
        // Darkens the top and bottom edges so the back button and the title
        // stay readable over a bright photo.
        const _ImageScrim(),
        if (widget.images.length > 1)
          Positioned(
            bottom: AppSpacing.lg,
            left: 0,
            right: 0,
            child: _PageDots(
              count: widget.images.length,
              current: _currentPage,
            ),
          ),
      ],
    );
  }
}

class _ImageScrim extends StatelessWidget {
  const _ImageScrim();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.black.withValues(alpha: 0.45),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.35),
          ],
          stops: const <double>[0, 0.28, 0.62, 1],
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int current;

  const _PageDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: AppDurations.fast,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            // The active dot stretches into a pill rather than only changing
            // colour, so the position is readable at a glance.
            width: i == current ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == current
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
              borderRadius: AppRadius.pillAll,
            ),
          ),
      ],
    );
  }
}
