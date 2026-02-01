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
    int tabletLandscapeCrossAxisCount = 5,
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

  static double getFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final isLandscapeMode = isLandscape(context);
    final deviceType = getDeviceType(context);

    if (deviceType == DeviceType.tablet && isLandscapeMode) {
      return mobile;
    }

    return value<double>(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  static double getPadding(
    BuildContext context, {
    double mobile = 16,
    double tablet = 24,
    double desktop = 32,
  }) {
    final isLandscapeMode = isLandscape(context);
    final deviceType = getDeviceType(context);

    if (deviceType == DeviceType.tablet && isLandscapeMode) {
      return mobile;
    }

    return value<double>(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  static double getSpacing(
    BuildContext context, {
    double mobile = 8,
    double tablet = 12,
    double desktop = 16,
  }) {
    final isLandscapeMode = isLandscape(context);
    final deviceType = getDeviceType(context);

    if (deviceType == DeviceType.tablet && isLandscapeMode) {
      return mobile;
    }

    return value<double>(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  static double getIconSize(
    BuildContext context, {
    double mobile = 24,
    double tablet = 28,
    double desktop = 32,
  }) {
    final isLandscapeMode = isLandscape(context);
    final deviceType = getDeviceType(context);

    if (deviceType == DeviceType.tablet && isLandscapeMode) {
      return mobile;
    }

    return value<double>(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  static double getCardMaxWidth(BuildContext context) {
    final deviceType = getDeviceType(context);
    final isLandscapeMode = isLandscape(context);

    switch (deviceType) {
      case DeviceType.desktop:
        return 250;
      case DeviceType.tablet:
        return isLandscapeMode ? 180 : 200;
      case DeviceType.mobile:
        return 180;
    }
  }

  static double getProductCardAspectRatio(BuildContext context) {
    final deviceType = getDeviceType(context);
    final isLandscapeMode = isLandscape(context);

    switch (deviceType) {
      case DeviceType.desktop:
        return 0.75;
      case DeviceType.tablet:
        return isLandscapeMode ? 0.78 : 0.68;
      case DeviceType.mobile:
        return 0.65;
    }
  }

  static double getDrawerWidth(BuildContext context) {
    final deviceType = getDeviceType(context);
    final screenW = screenWidth(context);
    final isLandscapeMode = isLandscape(context);

    switch (deviceType) {
      case DeviceType.desktop:
        return 300;
      case DeviceType.tablet:
        return isLandscapeMode ? screenW * 0.28 : screenW * 0.4;
      case DeviceType.mobile:
        return screenW * 0.85;
    }
  }

  static double getBottomSheetHeightRatio(BuildContext context) {
    final deviceType = getDeviceType(context);
    final isLandscapeMode = isLandscape(context);

    if (isLandscapeMode) {
      return 0.9;
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

  static bool shouldUseSideBySideLayout(BuildContext context) {
    return isTabletLandscape(context) || isDesktop(context);
  }

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

extension ResponsiveContext on BuildContext {
  bool get isMobile => ResponsiveHelper.isMobile(this);

  bool get isTablet => ResponsiveHelper.isTablet(this);

  bool get isDesktop => ResponsiveHelper.isDesktop(this);

  bool get isLandscape => ResponsiveHelper.isLandscape(this);

  bool get isPortrait => ResponsiveHelper.isPortrait(this);

  bool get isTabletLandscape => ResponsiveHelper.isTabletLandscape(this);

  DeviceType get deviceType => ResponsiveHelper.getDeviceType(this);

  double get screenWidth => ResponsiveHelper.screenWidth(this);

  double get screenHeight => ResponsiveHelper.screenHeight(this);

  double get responsivePadding => ResponsiveHelper.getPadding(this);

  double get responsiveSpacing => ResponsiveHelper.getSpacing(this);

  bool get shouldUseSideBySide =>
      ResponsiveHelper.shouldUseSideBySideLayout(this);
}
