import 'package:pos/pages/customer.dart';
import 'package:pos/pages/customer/customer_form.dart';
import 'package:pos/pages/expenses.dart';
import 'package:pos/pages/home.dart';
import 'package:pos/pages/inventory.dart';
import 'package:pos/pages/inventory/csv_preview.dart';
import 'package:pos/pages/inventory/inventory_form.dart';
import 'package:pos/pages/login.dart';
import 'package:pos/pages/register.dart';
import 'package:pos/pages/report.dart';
import 'package:pos/pages/salaries.dart';
import 'package:pos/pages/salaries/salaries_form.dart';

import 'package:pos/pages/pos_modern/modern_print_setting.dart';
import 'package:pos/pages/pos_modern/staff_picker_page.dart';
import 'package:pos/pages/pos_modern/awaiting_orders_page.dart';
import 'package:pos/pages/store.dart';
import 'package:pos/pages/users.dart';
import 'package:pos/pages/users/user_form.dart';
import 'package:pos/pages/pos_modern/pos_modern_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'router.g.dart';

@TypedGoRoute<StaffPickerRoute>(path: '/staff')
class StaffPickerRoute extends GoRouteData {
  const StaffPickerRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const StaffPickerPage();
}

@TypedGoRoute<PosModernRoute>(path: '/')
class PosModernRoute extends GoRouteData {
  const PosModernRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const PosModernPage();
}

@TypedGoRoute<AwaitingOrdersRoute>(path: '/awaiting-orders')
class AwaitingOrdersRoute extends GoRouteData {
  const AwaitingOrdersRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AwaitingOrdersPage();
}


@TypedGoRoute<HomeRoute>(
  path: '/home',
)
class HomeRoute extends GoRouteData {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Home();
}

@TypedGoRoute<StoreRoute>(path: '/store')
class StoreRoute extends GoRouteData {
  const StoreRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Store();
}

@TypedGoRoute<InventoryRoute>(
  path: '/inventory',
  routes: <TypedGoRoute<GoRouteData>>[
    TypedGoRoute<InventoryFormRoute>(
      path: 'form',
    )
  ],
)
class InventoryRoute extends GoRouteData {
  const InventoryRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Inventory();
}

class InventoryFormRoute extends GoRouteData {
  const InventoryFormRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => InventoryForm();
}

@TypedGoRoute<ReportRoute>(path: '/report')
class ReportRoute extends GoRouteData {
  const ReportRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Report();
}

@TypedGoRoute<UserRoute>(
  path: '/users',
  routes: <TypedGoRoute<GoRouteData>>[
    TypedGoRoute<UserFormRoute>(
      path: 'form',
    )
  ],
)
class UserRoute extends GoRouteData {
  const UserRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Users();
}

class UserFormRoute extends GoRouteData {
  const UserFormRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => UserForm();
}

@TypedGoRoute<CustomerRoute>(
  path: '/customer',
  routes: <TypedGoRoute<GoRouteData>>[
    TypedGoRoute<CustomerFormRoute>(
      path: 'form',
    )
  ],
)
class CustomerRoute extends GoRouteData {
  const CustomerRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Customer();
}

class CustomerFormRoute extends GoRouteData {
  const CustomerFormRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => CustomerForm();
}

@TypedGoRoute<CsvPreviewRoute>(path: '/csv-preview')
class CsvPreviewRoute extends GoRouteData {
  const CsvPreviewRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const CsvPreview();
}

@TypedGoRoute<PrintSettingRoute>(path: '/print-setting')
class PrintSettingRoute extends GoRouteData {
  const PrintSettingRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ModernPrintSetting();
}

@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData {
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Login();
}

@TypedGoRoute<RegisterRoute>(path: '/register')
class RegisterRoute extends GoRouteData {
  const RegisterRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Register();
}


@TypedGoRoute<ExpensesRoute>(path: '/expenses')
class ExpensesRoute extends GoRouteData {
  const ExpensesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Expanses();
}

@TypedGoRoute<SalariesRoute>(
  path: '/salaries',
  routes: <TypedGoRoute<GoRouteData>>[
    TypedGoRoute<SalariesFormRoute>(
      path: 'form',
    )
  ],
)
class SalariesRoute extends GoRouteData {
  const SalariesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Salaries();
}

class SalariesFormRoute extends GoRouteData {
  const SalariesFormRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SalariesForm();
}
