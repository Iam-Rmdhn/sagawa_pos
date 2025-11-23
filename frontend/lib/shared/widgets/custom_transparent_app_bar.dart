import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom transparent app bar that can be used across all screens
/// to avoid cutting off the screen background colors
class CustomTransparentAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CustomTransparentAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.elevation = 0,
    this.centerTitle = true,
    this.titleStyle,
    this.iconColor,
    this.systemOverlayStyle,
    this.automaticallyImplyLeading = true,
    this.toolbarHeight,
    this.leadingWidth,
    this.bottom,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final double elevation;
  final bool centerTitle;
  final TextStyle? titleStyle;
  final Color? iconColor;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final bool automaticallyImplyLeading;
  final double? toolbarHeight;
  final double? leadingWidth;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      leading: leading,
      actions: actions,
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: elevation,
      centerTitle: centerTitle,
      titleTextStyle: titleStyle,
      iconTheme: IconThemeData(color: iconColor ?? Colors.white),
      systemOverlayStyle:
          systemOverlayStyle ??
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
      automaticallyImplyLeading: automaticallyImplyLeading,
      toolbarHeight: toolbarHeight,
      leadingWidth: leadingWidth,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize {
    final double height = toolbarHeight ?? kToolbarHeight;
    final double bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(height + bottomHeight);
  }
}

/// Custom app bar with rounded bottom corners
class CustomRoundedAppBar extends StatelessWidget {
  const CustomRoundedAppBar({
    super.key,
    this.title = '',
    this.onBackTap,
    this.backgroundColor = const Color(0xFFFF4B4B),
    this.borderRadius = 24.0,
    this.titleStyle,
    this.showBackButton = true,
    this.backButtonIcon,
    this.actions,
    this.height = 100.0,
  });

  final String title;
  final VoidCallback? onBackTap;
  final Color backgroundColor;
  final double borderRadius;
  final TextStyle? titleStyle;
  final bool showBackButton;
  final Widget? backButtonIcon;
  final List<Widget>? actions;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(borderRadius),
        bottomRight: Radius.circular(borderRadius),
      ),
      child: Container(
        color: backgroundColor,
        child: SafeArea(
          bottom: false,
          child: Container(
            height: height - MediaQuery.of(context).padding.top,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(color: backgroundColor),
            child: Row(
              children: [
                if (showBackButton)
                  GestureDetector(
                    onTap: onBackTap ?? () => Navigator.of(context).pop(),
                    child:
                        backButtonIcon ??
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                  )
                else
                  const SizedBox(width: 40),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style:
                        titleStyle ??
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (actions != null && actions!.isNotEmpty)
                  Row(mainAxisSize: MainAxisSize.min, children: actions!)
                else
                  const SizedBox(width: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom app bar with gradient background
class CustomGradientAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CustomGradientAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.gradientColors = const [Color(0xFFFF4B4B), Color(0xFFFF6B6B)],
    this.elevation = 0,
    this.centerTitle = true,
    this.titleStyle,
    this.iconColor,
    this.toolbarHeight,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final List<Color> gradientColors;
  final double elevation;
  final bool centerTitle;
  final TextStyle? titleStyle;
  final Color? iconColor;
  final double? toolbarHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: AppBar(
        title: title,
        leading: leading,
        actions: actions,
        backgroundColor: Colors.transparent,
        elevation: elevation,
        centerTitle: centerTitle,
        titleTextStyle: titleStyle,
        iconTheme: IconThemeData(color: iconColor ?? Colors.white),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        toolbarHeight: toolbarHeight,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight ?? kToolbarHeight);
}
