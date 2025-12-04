import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

enum DeviceOrientation { portrait, landscape }

class ResponsiveHelper {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < desktopBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static bool isTabletLandscape(BuildContext context) {
    return isTablet(context) && isLandscape(context);
  }

  static bool isTabletPortrait(BuildContext context) {
    return isTablet(context) && isPortrait(context);
  }

  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static EdgeInsets safeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }

  static T orientationValue<T>({
    required BuildContext context,
    required T portrait,
    required T landscape,
  }) {
    return isLandscape(context) ? landscape : portrait;
  }

  static int getGridCrossAxisCount(
    BuildContext context, {
    int mobileCrossAxisCount = 2,
    int tabletPortraitCrossAxisCount = 3,
    int tabletLandscapeCrossAxisCount = 5, // More columns for compact view
    int desktopCrossAxisCount = 6,
  }) {
    final deviceType = getDeviceType(context);
    final isLandscapeMode = isLandscape(context);

    switch (deviceType) {
      case DeviceType.desktop:
        return desktopCrossAxisCount;
      case DeviceType.tablet:
        return isLandscapeMode
            ? tabletLandscapeCrossAxisCount
            : tabletPortraitCrossAxisCount;
      case DeviceType.mobile:
        return isLandscapeMode
            ? mobileCrossAxisCount + 1
            : mobileCrossAxisCount;
    }
  }

  /// Get responsive font size
  static double getFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final isLandscapeMode = isLandscape(context);
    final deviceType = getDeviceType(context);

    // Reduce font size in tablet landscape for compact view
    if (deviceType == DeviceType.tablet && isLandscapeMode) {
      return mobile; // Use mobile size for compact view
    }

    return value<double>(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Get responsive padding
  static double getPadding(
    BuildContext context, {
    double mobile = 16,
    double tablet = 24,
    double desktop = 32,
  }) {
    final isLandscapeMode = isLandscape(context);
    final deviceType = getDeviceType(context);

    // Use smaller padding in tablet landscape for compact view
    if (deviceType == DeviceType.tablet && isLandscapeMode) {
      return mobile; // Use mobile padding for compact view
    }

    return value<double>(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Get responsive spacing
  static double getSpacing(
    BuildContext context, {
    double mobile = 8,
    double tablet = 12,
    double desktop = 16,
  }) {
    final isLandscapeMode = isLandscape(context);
    final deviceType = getDeviceType(context);

    // Use smaller spacing in tablet landscape for compact view
    if (deviceType == DeviceType.tablet && isLandscapeMode) {
      return mobile; // Use mobile spacing for compact view
    }

    return value<double>(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Get responsive icon size
  static double getIconSize(
    BuildContext context, {
    double mobile = 24,
    double tablet = 28,
    double desktop = 32,
  }) {
    final isLandscapeMode = isLandscape(context);
    final deviceType = getDeviceType(context);

    // Use smaller icon in tablet landscape for compact view
    if (deviceType == DeviceType.tablet && isLandscapeMode) {
      return mobile; // Use mobile icon size for compact view
    }

    return value<double>(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Get responsive card width for grid items
  static double getCardMaxWidth(BuildContext context) {
    final deviceType = getDeviceType(context);
    final isLandscapeMode = isLandscape(context);

    switch (deviceType) {
      case DeviceType.desktop:
        return 250;
      case DeviceType.tablet:
        return isLandscapeMode ? 180 : 200; // Smaller cards in landscape
      case DeviceType.mobile:
        return 180;
    }
  }

  /// Get responsive aspect ratio for product cards
  static double getProductCardAspectRatio(BuildContext context) {
    final deviceType = getDeviceType(context);
    final isLandscapeMode = isLandscape(context);

    switch (deviceType) {
      case DeviceType.desktop:
        return 0.75;
      case DeviceType.tablet:
        return isLandscapeMode
            ? 0.78
            : 0.68; // More square in landscape for compact
      case DeviceType.mobile:
        return 0.65;
    }
  }

  /// Get drawer width for tablet/desktop
  static double getDrawerWidth(BuildContext context) {
    final deviceType = getDeviceType(context);
    final screenW = screenWidth(context);
    final isLandscapeMode = isLandscape(context);

    switch (deviceType) {
      case DeviceType.desktop:
        return 300;
      case DeviceType.tablet:
        // Smaller drawer in landscape for compact view
        return isLandscapeMode ? screenW * 0.28 : screenW * 0.4;
      case DeviceType.mobile:
        return screenW * 0.85;
    }
  }

  /// Get bottom sheet height ratio
  static double getBottomSheetHeightRatio(BuildContext context) {
    final deviceType = getDeviceType(context);
    final isLandscapeMode = isLandscape(context);

    if (isLandscapeMode) {
      return 0.9; // Use more height in landscape
    }

    switch (deviceType) {
      case DeviceType.desktop:
        return 0.6;
      case DeviceType.tablet:
        return 0.7;
      case DeviceType.mobile:
        return 0.85;
    }
  }

  /// Get dialog width
  static double getDialogWidth(BuildContext context) {
    final deviceType = getDeviceType(context);
    final screenW = screenWidth(context);

    switch (deviceType) {
      case DeviceType.desktop:
        return 500;
      case DeviceType.tablet:
        return screenW * 0.6;
      case DeviceType.mobile:
        return screenW * 0.9;
    }
  }

  /// Check if should use side-by-side layout (for order page)
  static bool shouldUseSideBySideLayout(BuildContext context) {
    return isTabletLandscape(context) || isDesktop(context);
  }

  /// Get content max width for centered layouts
  static double getContentMaxWidth(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.desktop:
        return 1200;
      case DeviceType.tablet:
        return 900;
      case DeviceType.mobile:
        return double.infinity;
    }
  }
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    DeviceType deviceType,
    bool isLandscape,
  )
  builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = ResponsiveHelper.getDeviceType(context);
        final isLandscape = ResponsiveHelper.isLandscape(context);
        return builder(context, deviceType, isLandscape);
      },
    );
  }
}

/// Responsive layout widget for different screen sizes
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
    return ResponsiveBuilder(
      builder: (context, deviceType, isLandscape) {
        switch (deviceType) {
          case DeviceType.desktop:
            return desktop ?? tablet ?? mobile;
          case DeviceType.tablet:
            return tablet ?? mobile;
          case DeviceType.mobile:
            return mobile;
        }
      },
    );
  }
}

/// Orientation-aware layout widget
class OrientationLayout extends StatelessWidget {
  final Widget portrait;
  final Widget landscape;

  const OrientationLayout({
    super.key,
    required this.portrait,
    required this.landscape,
  });

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return orientation == Orientation.landscape ? landscape : portrait;
      },
    );
  }
}

/// Extension on BuildContext for easy access to responsive helpers
extension ResponsiveContext on BuildContext {
  /// Check if device is mobile
  bool get isMobile => ResponsiveHelper.isMobile(this);

  /// Check if device is tablet
  bool get isTablet => ResponsiveHelper.isTablet(this);

  /// Check if device is desktop
  bool get isDesktop => ResponsiveHelper.isDesktop(this);

  /// Check if device is in landscape mode
  bool get isLandscape => ResponsiveHelper.isLandscape(this);

  /// Check if device is in portrait mode
  bool get isPortrait => ResponsiveHelper.isPortrait(this);

  /// Check if device is tablet in landscape mode
  bool get isTabletLandscape => ResponsiveHelper.isTabletLandscape(this);

  /// Get device type
  DeviceType get deviceType => ResponsiveHelper.getDeviceType(this);

  /// Get screen width
  double get screenWidth => ResponsiveHelper.screenWidth(this);

  /// Get screen height
  double get screenHeight => ResponsiveHelper.screenHeight(this);

  /// Get responsive padding
  double get responsivePadding => ResponsiveHelper.getPadding(this);

  /// Get responsive spacing
  double get responsiveSpacing => ResponsiveHelper.getSpacing(this);

  /// Check if should use side-by-side layout
  bool get shouldUseSideBySide =>
      ResponsiveHelper.shouldUseSideBySideLayout(this);
}
