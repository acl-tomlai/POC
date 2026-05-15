import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/auth_api.dart';
import '../api/categories_api.dart';
import '../api/orders_api.dart';
import '../api/payments_api.dart';
import '../api/printers_api.dart';
import '../api/products_api.dart';
import '../api/stores_api.dart';
import '../api/tenants_api.dart';
import '../api/users_api.dart';
import '../models/category.dart';
import '../models/printer.dart';
import '../models/product.dart';
import '../services/drawer_service.dart';
import '../services/localization_service.dart';
import '../services/printer_service.dart';
import '../services/secure_credentials.dart';
import 'cart_state.dart';
import 'device_state.dart';
import 'session_state.dart';

// ---------- low-level services ----------

final Provider<SecureCredentialsService> secureCredentialsProvider =
    Provider<SecureCredentialsService>((Ref ref) => SecureCredentialsService());

// ---------- device + session ----------

final StateNotifierProvider<DeviceStateNotifier, DeviceState>
    deviceStateProvider = StateNotifierProvider<DeviceStateNotifier, DeviceState>(
  (Ref ref) => DeviceStateNotifier(ref.read(secureCredentialsProvider)),
);

final StateNotifierProvider<SessionStateNotifier, SessionState>
    sessionStateProvider =
    StateNotifierProvider<SessionStateNotifier, SessionState>(
  (Ref ref) => SessionStateNotifier(),
);

final StateNotifierProvider<CartNotifier, OrderDraft> cartProvider =
    StateNotifierProvider<CartNotifier, OrderDraft>((Ref ref) => CartNotifier());

// ---------- API client (auto JWT injection + 401 -> session signOut) ----------

final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((Ref ref) {
  return ApiClient(
    tokenProvider: () {
      final String? sessionToken = ref.read(sessionStateProvider).token;
      if (sessionToken != null) return sessionToken;
      return ref.read(deviceStateProvider).credentials?.token;
    },
    onUnauthorized: () {
      // Drop the in-memory cashier session. The encrypted blob on disk stays.
      ref.read(sessionStateProvider.notifier).signOut();
    },
  );
});

final Provider<AuthApi> authApiProvider =
    Provider<AuthApi>((Ref ref) => AuthApi(ref.watch(apiClientProvider)));
final Provider<UsersApi> usersApiProvider =
    Provider<UsersApi>((Ref ref) => UsersApi(ref.watch(apiClientProvider)));
final Provider<StoresApi> storesApiProvider =
    Provider<StoresApi>((Ref ref) => StoresApi(ref.watch(apiClientProvider)));
final Provider<CategoriesApi> categoriesApiProvider =
    Provider<CategoriesApi>((Ref ref) => CategoriesApi(ref.watch(apiClientProvider)));
final Provider<ProductsApi> productsApiProvider =
    Provider<ProductsApi>((Ref ref) => ProductsApi(ref.watch(apiClientProvider)));
final Provider<PrintersApi> printersApiProvider =
    Provider<PrintersApi>((Ref ref) => PrintersApi(ref.watch(apiClientProvider)));
final Provider<OrdersApi> ordersApiProvider =
    Provider<OrdersApi>((Ref ref) => OrdersApi(ref.watch(apiClientProvider)));
final Provider<PaymentsApi> paymentsApiProvider =
    Provider<PaymentsApi>((Ref ref) => PaymentsApi(ref.watch(apiClientProvider)));
final Provider<TenantsApi> tenantsApiProvider =
    Provider<TenantsApi>((Ref ref) => TenantsApi(ref.watch(apiClientProvider)));

// ---------- cashier tiles (rebuilt after add/remove) ----------

final FutureProvider<List<CashierEntry>> cashierEntriesProvider =
    FutureProvider<List<CashierEntry>>((Ref ref) async {
  return ref.read(secureCredentialsProvider).listCashiers();
});

// ---------- printing / l10n services ----------

final Provider<LocalizationService> localizationServiceProvider =
    Provider<LocalizationService>((Ref ref) => const LocalizationService());

final Provider<PrinterService> printerServiceProvider =
    Provider<PrinterService>(
  (Ref ref) => PrinterService(l10n: ref.watch(localizationServiceProvider)),
);

final Provider<DrawerService> drawerServiceProvider = Provider<DrawerService>(
  (Ref ref) => DrawerService(ref.watch(printerServiceProvider)),
);

// ---------- catalog data (loaded once on till boot, cached) ----------

final FutureProvider<List<Category>> categoriesProvider =
    FutureProvider<List<Category>>(
  (Ref ref) async => ref.read(categoriesApiProvider).list(),
);

final FutureProvider<List<Product>> productsProvider =
    FutureProvider<List<Product>>(
  (Ref ref) async => ref.read(productsApiProvider).list(),
);

final FutureProvider<List<Printer>> activeStorePrintersProvider =
    FutureProvider<List<Printer>>((Ref ref) async {
  final String? storeId = ref.watch(deviceStateProvider).credentials?.storeId;
  if (storeId == null || storeId.isEmpty) return <Printer>[];
  return ref.read(printersApiProvider).listForStore(storeId);
});
