import 'package:flutter/material.dart';
import 'package:sagawa_pos_new/core/utils/responsive_helper.dart';

/// A wrapper widget that provides responsive layout capabilities
/// Useful for wrapping page content to make it responsive
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final bool centerContent;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.centerContent = false,
    this.maxWidth,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    // Apply max width constraint for larger screens
    if (centerContent) {
      final effectiveMaxWidth =
          maxWidth ?? ResponsiveHelper.getContentMaxWidth(context);
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          child: content,
        ),
      );
    }

    // Apply responsive padding
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    // Apply background color
    if (backgroundColor != null) {
      content = ColoredBox(color: backgroundColor!, child: content);
    }

    return content;
  }
}

/// A scaffold wrapper that handles responsive navigation (drawer vs rail vs permanent sidebar)
class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final Widget? drawer;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool showDrawerOnTablet;
  final Widget? permanentSidebar;
  final double sidebarWidth;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.drawer,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.showDrawerOnTablet = true,
    this.permanentSidebar,
    this.sidebarWidth = 280,
  });

  @override
  Widget build(BuildContext context) {
    final isTabletLandscape = context.isTabletLandscape;
    final isDesktop = context.isDesktop;

    // For tablet landscape or desktop with permanent sidebar
    if ((isTabletLandscape || isDesktop) && permanentSidebar != null) {
      return Scaffold(
        appBar: appBar,
        backgroundColor: backgroundColor,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        body: Row(
          children: [
            SizedBox(width: sidebarWidth, child: permanentSidebar),
            Expanded(child: body),
          ],
        ),
      );
    }

    // For mobile and tablet portrait - use drawer
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: body,
    );
  }
}

/// A widget that shows different content based on orientation
/// Particularly useful for iPad/tablet layouts
class AdaptiveOrientationLayout extends StatelessWidget {
  final Widget Function(BuildContext context) portraitBuilder;
  final Widget Function(BuildContext context) landscapeBuilder;

  const AdaptiveOrientationLayout({
    super.key,
    required this.portraitBuilder,
    required this.landscapeBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape) {
          return landscapeBuilder(context);
        }
        return portraitBuilder(context);
      },
    );
  }
}

/// A responsive padding widget
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final double? mobile;
  final double? tablet;
  final double? desktop;
  final bool horizontal;
  final bool vertical;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobile,
    this.tablet,
    this.desktop,
    this.horizontal = true,
    this.vertical = true,
  });

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getPadding(
      context,
      mobile: mobile ?? 16,
      tablet: tablet ?? 24,
      desktop: desktop ?? 32,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal ? padding : 0,
        vertical: vertical ? padding : 0,
      ),
      child: child,
    );
  }
}

/// A responsive sized box for spacing
class ResponsiveSpacing extends StatelessWidget {
  final double? mobile;
  final double? tablet;
  final double? desktop;
  final bool isVertical;

  const ResponsiveSpacing({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.isVertical = true,
  });

  const ResponsiveSpacing.vertical({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
  }) : isVertical = true;

  const ResponsiveSpacing.horizontal({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
  }) : isVertical = false;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveHelper.getSpacing(
      context,
      mobile: mobile ?? 8,
      tablet: tablet ?? 12,
      desktop: desktop ?? 16,
    );

    return SizedBox(
      height: isVertical ? spacing : null,
      width: isVertical ? null : spacing,
    );
  }
}

/// A two-pane layout for tablet landscape mode
/// Shows master-detail view side by side
class TwoPaneLayout extends StatelessWidget {
  final Widget masterPane;
  final Widget detailPane;
  final double masterPaneWidth;
  final double? minDetailPaneWidth;
  final bool showDivider;
  final Color? dividerColor;

  const TwoPaneLayout({
    super.key,
    required this.masterPane,
    required this.detailPane,
    this.masterPaneWidth = 0.4,
    this.minDetailPaneWidth,
    this.showDivider = true,
    this.dividerColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final masterWidth = constraints.maxWidth * masterPaneWidth;

        return Row(
          children: [
            SizedBox(width: masterWidth, child: masterPane),
            if (showDivider)
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: dividerColor ?? Colors.grey.shade300,
              ),
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: minDetailPaneWidth ?? 300,
                ),
                child: detailPane,
              ),
            ),
          ],
        );
      },
    );
  }
}
