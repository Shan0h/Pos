import 'package:flutter/material.dart';

class Breakpoints {
  static const double mobileMax = 450;
  static const double tabletMax = 1200;

  static bool isMobile(double width) => width <= mobileMax;
  static bool isTablet(double width) => width > mobileMax && width <= tabletMax;
  static bool isDesktop(double width) => width > tabletMax;
}

class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (Breakpoints.isDesktop(constraints.maxWidth)) {
          return desktop ?? tablet ?? mobile;
        }
        if (Breakpoints.isTablet(constraints.maxWidth)) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}

class ResponsiveConstrainedBox extends StatelessWidget {
  final Widget child;
  final double mobileMaxWidth;
  final double tabletMaxWidth;
  final double desktopMaxWidth;

  const ResponsiveConstrainedBox({
    super.key,
    required this.child,
    this.mobileMaxWidth = 350,
    this.tabletMaxWidth = 500,
    this.desktopMaxWidth = 400,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth;
        if (Breakpoints.isDesktop(constraints.maxWidth)) {
          maxWidth = desktopMaxWidth;
        } else if (Breakpoints.isTablet(constraints.maxWidth)) {
          maxWidth = tabletMaxWidth;
        } else {
          maxWidth = mobileMaxWidth;
        }
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}

class ResponsiveRowColumn extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const ResponsiveRowColumn({
    super.key,
    required this.children,
    this.spacing = 16,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (Breakpoints.isMobile(constraints.maxWidth)) {
          return Column(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: _withSpacing(children),
          );
        }
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children,
        );
      },
    );
  }

  List<Widget> _withSpacing(List<Widget> widgets) {
    if (widgets.isEmpty) return widgets;
    final result = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) {
        result.add(SizedBox(height: spacing));
      }
    }
    return result;
  }
}
