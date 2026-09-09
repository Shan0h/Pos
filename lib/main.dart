import 'dart:async';
import 'dart:developer';

import 'package:pos/controller/theme_controller.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pos/controller/auth_controller.dart';
import 'package:pos/controller/selling_controller.dart';
import 'package:pos/controller/store_controller.dart';
import 'package:pos/model/auth_model.dart';
import 'package:pos/routes/router.dart';
import 'package:pos/service/database.dart';
import 'package:pos/service/get_it.dart';
import 'package:pos/utils/env.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:signals/signals_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final isDeviceConnected = signal(false);

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF8B5E3C),
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor:
        isDark ? const Color(0xFF1A1410) : const Color(0xFFFAF6F2),
    cardColor: isDark ? const Color(0xFF241C16) : Colors.white,
    dividerColor: isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF2D2318) : const Color(0xFFF5EDE4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF8B5E3C)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? const Color(0xFF3E2723) : const Color(0xFF3E2723),
      contentTextStyle: const TextStyle(color: Colors.white),
    ),
  );
}

final _lightTheme = _buildTheme(Brightness.light);
final _darkTheme = _buildTheme(Brightness.dark);
final _lightShadTheme = ShadThemeData(
  brightness: Brightness.light,
  colorScheme: const ShadStoneColorScheme.light(),
);
final _darkShadTheme = ShadThemeData(
  brightness: Brightness.dark,
  colorScheme: const ShadStoneColorScheme.dark(),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: Environment.url,
    publishableKey: Environment.anonKey,
  );
  setup();
  await getIt.get<Database>().db;
  // Warm up the store signal so first-use consumers (checkout, Owner PIN,
  // Store form, report PDFs) never read a null value mid-load.
  await storeController.store.future;
  runApp(const MyApp());
}

final _router = GoRouter(routes: $appRoutes);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription<List<ConnectivityResult>> subscription;
  AsyncState<AuthModel?> _authState = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    _refreshConnectionStatus();
    _authState = authController.customer.peek();

    subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) async {
      await _refreshConnectionStatus();
      log("Internet status ====== $isDeviceConnected");
    });

    effect(() {
      _authState = authController.customer.value;
      if (_authState is AsyncData<AuthModel?>) {
        getIt.get<SellingController>().staffId.value =
            (_authState as AsyncData<AuthModel?>).value?.user.value;
      }
    });
  }

  Future<void> _refreshConnectionStatus() async {
    isDeviceConnected.value = await InternetConnectionChecker().hasConnection;
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    authController.customer.watch(context);
    final themeMode = themeController.mode.watch(context);

    return ShadApp.materialRouter(
      debugShowCheckedModeBanner: false,
      title: 'POS',
      routerConfig: _router,
      theme: _lightShadTheme,
      darkTheme: _darkShadTheme,
      themeMode: themeMode,
      materialThemeBuilder: (context, theme) =>
          theme.brightness == Brightness.dark ? _darkTheme : _lightTheme,
    );
  }
}
