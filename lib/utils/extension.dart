import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' show window;
import 'package:pos/widget/responsive_wrapper.dart';

extension MediaQueryValues on BuildContext {
  double get width => MediaQuery.of(this).size.width;
  double get height => MediaQuery.of(this).size.height;
  bool get isMobile => MediaQuery.of(this).size.width <= Breakpoints.mobileMax;
  bool get isTablet =>
      MediaQuery.of(this).size.width > Breakpoints.mobileMax &&
      MediaQuery.of(this).size.width <= Breakpoints.tabletMax;
  bool get isDesktop => MediaQuery.of(this).size.width > Breakpoints.tabletMax;
}

extension DarkMode on BuildContext {
  /// is dark mode currently enabled?
  bool get isDarkMode {
    return Theme.of(this).brightness == Brightness.dark;
  }

  ThemeData get theme => Theme.of(this);

  Color get pageBackground =>
      isDarkMode ? const Color(0xFF1A1410) : const Color(0xFFFAF6F2);

  Color get panelBackground =>
      isDarkMode ? const Color(0xFF241C16) : Colors.white;

  Color get mutedBackground =>
      isDarkMode ? const Color(0xFF2D2318) : const Color(0xFFF5EDE4);

  Color get borderColor => isDarkMode
      ? Colors.white.withValues(alpha: 0.12)
      : Colors.black.withValues(alpha: 0.08);

  Color get appTextColor => theme.colorScheme.onSurface;

  Color get secondaryTextColor =>
      isDarkMode ? Colors.white70 : Colors.black54;

  Color get subtleTextColor =>
      isDarkMode ? Colors.white60 : Colors.grey.shade600;

  Color get appShadowColor =>
      Colors.black.withValues(alpha: isDarkMode ? 0.25 : 0.05);
}

extension PlatformExtension on Platform {
  static String get _webPlatform =>
      window.navigator.platform?.toLowerCase() ?? '';

  /// Returns true if the operating system is macOS and not running on Web platform.
  static bool get isMacOS {
    if (kIsWeb) {
      return false;
    }
    return Platform.isMacOS;
  }

  /// Returns true if the operating system is Windows and not running on Web platform.
  static bool get isWindows {
    if (kIsWeb) {
      return false;
    }
    return Platform.isWindows;
  }

  /// Returns true if the operating system is Linux and not running on Web platform.
  static bool get isLinux {
    if (kIsWeb) {
      return false;
    }
    return Platform.isLinux;
  }

  /// Returns true if the operating system is macOS and running on Web platform.
  static bool get isWebOnMacOS {
    if (!kIsWeb) {
      return false;
    }
    return _webPlatform.contains('mac') == true;
  }

  /// Returns true if the operating system is Windows and running on Web platform.
  static bool get isWebOnWindows {
    if (!kIsWeb) {
      return false;
    }
    return _webPlatform.contains('windows') == true;
  }

  /// Returns true if the operating system is Linux and running on Web platform.
  static bool get isWebOnLinux {
    if (!kIsWeb) {
      return false;
    }
    return _webPlatform.contains('linux') == true;
  }

  static bool get isDesktopOrWeb {
    if (kIsWeb) {
      return true;
    }
    return isDesktop;
  }

  static bool get isDesktop {
    if (kIsWeb) {
      return false;
    }
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  static bool get isMobile {
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid || Platform.isIOS;
  }

  static bool get isNotMobile {
    if (kIsWeb) {
      return false;
    }
    return !isMobile;
  }
}
