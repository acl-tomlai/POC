import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/add_user.dart';
import '../screens/customer/customer_display.dart';
import '../screens/customer/customer_pairing.dart';
import '../screens/device_setup.dart';
import '../screens/order_summary.dart';
import '../screens/payment.dart';
import '../screens/settings.dart';
import '../screens/splash.dart';
import '../screens/till_home.dart';
import '../screens/user_picker.dart';

/// Top-level Till app routes.
class TillRoutes {
  static const String splash = '/';
  static const String deviceSetup = '/device-setup';
  static const String userPicker = '/users';
  static const String addUser = '/users/add';
  static const String tillHome = '/till';
  static const String payment = '/till/pay';
  static const String orderSummary = '/till/summary';
  static const String settings = '/settings';
}

/// Top-level Customer-display app routes.
class CustomerRoutes {
  static const String pairing = '/';
  static const String display = '/display';
}

final Provider<GoRouter> tillRouterProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    initialLocation: TillRoutes.splash,
    routes: <RouteBase>[
      GoRoute(
        path: TillRoutes.splash,
        builder: (BuildContext c, GoRouterState s) => const SplashScreen(),
      ),
      GoRoute(
        path: TillRoutes.deviceSetup,
        builder: (BuildContext c, GoRouterState s) => const DeviceSetupScreen(),
      ),
      GoRoute(
        path: TillRoutes.userPicker,
        builder: (BuildContext c, GoRouterState s) => const UserPickerScreen(),
      ),
      GoRoute(
        path: TillRoutes.addUser,
        builder: (BuildContext c, GoRouterState s) => const AddUserScreen(),
      ),
      GoRoute(
        path: TillRoutes.tillHome,
        builder: (BuildContext c, GoRouterState s) => const TillHomeScreen(),
      ),
      GoRoute(
        path: TillRoutes.payment,
        builder: (BuildContext c, GoRouterState s) => const PaymentScreen(),
      ),
      GoRoute(
        path: TillRoutes.orderSummary,
        builder: (BuildContext c, GoRouterState s) => const OrderSummaryScreen(),
      ),
      GoRoute(
        path: TillRoutes.settings,
        builder: (BuildContext c, GoRouterState s) => const SettingsScreen(),
      ),
    ],
  );
});

final Provider<GoRouter> customerRouterProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    initialLocation: CustomerRoutes.pairing,
    routes: <RouteBase>[
      GoRoute(
        path: CustomerRoutes.pairing,
        builder: (BuildContext c, GoRouterState s) => const CustomerPairingScreen(),
      ),
      GoRoute(
        path: CustomerRoutes.display,
        builder: (BuildContext c, GoRouterState s) => const CustomerDisplayScreen(),
      ),
    ],
  );
});
