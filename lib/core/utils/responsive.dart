import 'package:flutter/material.dart';

/// Responsive breakpoints
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Screen size categories
enum ScreenSize { mobile, tablet, desktop }

/// Responsive helper class
class Responsive {
  final BuildContext context;
  late final double screenWidth;
  late final double screenHeight;
  late final ScreenSize screenSize;
  late final Orientation orientation;

  Responsive(this.context) {
    final mediaQuery = MediaQuery.of(context);
    screenWidth = mediaQuery.size.width;
    screenHeight = mediaQuery.size.height;
    orientation = mediaQuery.orientation;
    
    if (screenWidth < Breakpoints.mobile) {
      screenSize = ScreenSize.mobile;
    } else if (screenWidth < Breakpoints.tablet) {
      screenSize = ScreenSize.tablet;
    } else {
      screenSize = ScreenSize.desktop;
    }
  }

  /// Check if current screen is mobile
  bool get isMobile => screenSize == ScreenSize.mobile;

  /// Check if current screen is tablet
  bool get isTablet => screenSize == ScreenSize.tablet;

  /// Check if current screen is desktop
  bool get isDesktop => screenSize == ScreenSize.desktop;

  /// Check if device is in landscape mode
  bool get isLandscape => orientation == Orientation.landscape;

  /// Check if device is in portrait mode
  bool get isPortrait => orientation == Orientation.portrait;

  /// Get responsive value based on screen size
  T value<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (screenSize) {
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.mobile:
        return mobile;
    }
  }

  /// Get number of grid columns based on screen size
  int get gridColumns => value(mobile: 2, tablet: 3, desktop: 4);

  /// Get number of horizontal list items visible
  int get horizontalListItems => value(mobile: 2, tablet: 4, desktop: 6);

  /// Get album card width based on screen size
  double get albumCardWidth {
    final padding = 32.0; // Total horizontal padding
    final spacing = 12.0 * (horizontalListItems - 1);
    final availableWidth = screenWidth - padding - spacing;
    return (availableWidth / horizontalListItems).clamp(120.0, 200.0);
  }

  /// Get playlist card width based on screen size
  double get playlistCardWidth => value(mobile: 150.0, tablet: 170.0, desktop: 200.0);

  /// Get track thumbnail size
  double get trackThumbnailSize => value(mobile: 48.0, tablet: 56.0, desktop: 64.0);

  /// Get now playing cover size
  double get nowPlayingCoverSize {
    final size = isLandscape ? screenHeight * 0.5 : screenWidth * 0.7;
    return size.clamp(200.0, 400.0);
  }

  /// Get horizontal padding
  double get horizontalPadding => value(mobile: 16.0, tablet: 24.0, desktop: 32.0);

  /// Get section spacing
  double get sectionSpacing => value(mobile: 24.0, tablet: 32.0, desktop: 40.0);

  /// Get card spacing
  double get cardSpacing => value(mobile: 12.0, tablet: 16.0, desktop: 20.0);

  /// Get mini player height
  double get miniPlayerHeight => value(mobile: 64.0, tablet: 72.0, desktop: 80.0);

  /// Get bottom nav height
  double get bottomNavHeight => value(mobile: 56.0, tablet: 64.0, desktop: 72.0);

  /// Calculate optimal grid item width
  double gridItemWidth({int minWidth = 140, int maxWidth = 200}) {
    final padding = horizontalPadding * 2;
    final spacing = cardSpacing * (gridColumns - 1);
    final availableWidth = screenWidth - padding - spacing;
    final itemWidth = availableWidth / gridColumns;
    return itemWidth.clamp(minWidth.toDouble(), maxWidth.toDouble());
  }
}

/// Responsive widget builder
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Responsive responsive) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, Responsive(context));
  }
}

/// Responsive layout widget
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.tablet) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= Breakpoints.mobile) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}

/// Extension on BuildContext for easy responsive access
extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive(this);
}
