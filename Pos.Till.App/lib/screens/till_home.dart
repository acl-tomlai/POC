import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/api_exception.dart';
import '../app/router.dart';
import '../models/category.dart';
import '../models/order.dart';
import '../models/printer.dart';
import '../models/product.dart';
import '../services/printer_service.dart';
import '../state/cart_state.dart';
import '../state/device_state.dart';
import '../state/providers.dart';
import '../state/session_state.dart';
import '../widgets/cart_panel.dart';
import '../widgets/product_grid.dart';

class TillHomeScreen extends ConsumerStatefulWidget {
  const TillHomeScreen({super.key});

  @override
  ConsumerState<TillHomeScreen> createState() => _TillHomeScreenState();
}

class _TillHomeScreenState extends ConsumerState<TillHomeScreen> {
  String? _selectedCategoryId; // null = "All"
  String _searchQuery = '';
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool compact = width < 720;
    final DeviceState device = ref.watch(deviceStateProvider);
    final SessionState session = ref.watch(sessionStateProvider);
    final AsyncValue<List<Category>> catsAsync = ref.watch(categoriesProvider);
    final AsyncValue<List<Product>> prodsAsync = ref.watch(productsProvider);

    if (!session.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(TillRoutes.userPicker);
      });
    }

    final String title = <String>[
      if (device.credentials?.restaurantName.isNotEmpty ?? false)
        device.credentials!.restaurantName,
      if (session.fullName != null) '${session.fullName} (${session.role ?? ''})',
    ].join(' · ');

    return Scaffold(
      appBar: AppBar(
        title: Text(title.isEmpty ? 'POS Till' : title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(TillRoutes.settings),
          ),
        ],
      ),
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => _ErrorRetry(
          message: e is ApiException ? e.message : e.toString(),
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
        data: (List<Category> cats) => prodsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, _) => _ErrorRetry(
            message: e is ApiException ? e.message : e.toString(),
            onRetry: () => ref.invalidate(productsProvider),
          ),
          data: (List<Product> all) => compact
              ? _buildStacked(cats, _filter(all))
              : _buildThreePane(cats, _filter(all)),
        ),
      ),
    );
  }

  List<Product> _filter(List<Product> all) {
    Iterable<Product> result = all.where((Product p) => p.isActive);
    if (_selectedCategoryId != null) {
      result = result.where((Product p) => p.categoryId == _selectedCategoryId);
    }
    if (_searchQuery.isNotEmpty) {
      final String q = _searchQuery.toLowerCase();
      result = result.where((Product p) {
        return p.name.toLowerCase().contains(q) ||
            (p.sku?.toLowerCase().contains(q) ?? false) ||
            (p.barcode?.toLowerCase().contains(q) ?? false);
      });
    }
    return result.toList();
  }

  Widget _buildThreePane(List<Category> cats, List<Product> filtered) {
    return Row(
      children: <Widget>[
        _CategoryRail(
          categories: cats,
          selectedId: _selectedCategoryId,
          onSelect: (String? id) => setState(() => _selectedCategoryId = id),
        ),
        const VerticalDivider(width: 1),
        Expanded(flex: 3, child: _buildProductPane(filtered)),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 2,
          child: CartPanel(
            sending: _sending,
            onSendToKitchen: _sendToKitchen,
            onPay: () => context.push(TillRoutes.payment),
          ),
        ),
      ],
    );
  }

  Widget _buildStacked(List<Category> cats, List<Product> filtered) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: cats.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (BuildContext c, int i) {
              if (i == 0) {
                return ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedCategoryId == null,
                  onSelected: (_) => setState(() => _selectedCategoryId = null),
                );
              }
              final Category cat = cats[i - 1];
              return ChoiceChip(
                label: Text(cat.name),
                selected: _selectedCategoryId == cat.id,
                onSelected: (_) =>
                    setState(() => _selectedCategoryId = cat.id),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildProductPane(filtered)),
        const Divider(height: 1),
        SizedBox(
          height: 320,
          child: CartPanel(
            sending: _sending,
            onSendToKitchen: _sendToKitchen,
            onPay: () => context.push(TillRoutes.payment),
          ),
        ),
      ],
    );
  }

  Widget _buildProductPane(List<Product> filtered) {
    final List<Product>? all = ref.read(productsProvider).valueOrNull;
    final int totalActive =
        all?.where((Product p) => p.isActive).length ?? 0;
    final String emptyMessage = _emptyMessageFor(totalActive);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SearchBar(
            hintText: 'Search name / SKU / barcode',
            leading: const Icon(Icons.search),
            onChanged: (String v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ProductGrid(
              products: filtered,
              emptyMessage: emptyMessage,
              onTap: (Product p) =>
                  ref.read(cartProvider.notifier).addProduct(p),
            ),
          ),
        ],
      ),
    );
  }

  String _emptyMessageFor(int totalActive) {
    if (totalActive == 0) {
      return 'No products configured yet — add some in the admin web.';
    }
    if (_searchQuery.isNotEmpty) {
      return 'No products match "$_searchQuery".';
    }
    if (_selectedCategoryId != null) {
      return 'No products in this category.';
    }
    return 'No products to show.';
  }

  Future<void> _sendToKitchen() async {
    final OrderDraft draft = ref.read(cartProvider);
    final DeviceState device = ref.read(deviceStateProvider);
    final String? storeId = device.credentials?.storeId;
    if (draft.isEmpty || storeId == null || storeId.isEmpty) return;

    setState(() => _sending = true);
    final ScaffoldMessengerState scaffold = ScaffoldMessenger.of(context);
    try {
      // 1. POST /api/orders
      final OrderCreateRequest req = OrderCreateRequest(
        storeId: storeId,
        discountAmount: draft.orderDiscount,
        taxAmount: draft.tax,
        lines: draft.lines
            .map((CartLine l) => OrderLineRequest(
                  productId: l.product.id,
                  quantity: l.quantity,
                  unitPrice: l.product.price,
                  discountAmount: l.discountAmount,
                ),)
            .toList(),
      );
      final Order created = await ref.read(ordersApiProvider).create(req);

      // 2. PUT status -> Sent
      final Order sent = await ref
          .read(ordersApiProvider)
          .updateStatus(created.id, OrderStatus.sent);
      ref
          .read(cartProvider.notifier)
          .bindServerOrder(id: sent.id, number: sent.orderNumber);

      // 3. Print to every kitchen-type printer
      final List<Printer> printers =
          await ref.read(activeStorePrintersProvider.future);
      final Iterable<Printer> kitchen = printers.where(
        (Printer p) => p.isActive && p.printerType == PrinterType.kitchen,
      );
      final List<String> printErrors = <String>[];
      for (final Printer p in kitchen) {
        final List<int> bytes = await ref.read(printerServiceProvider).buildKitchen(
              order: sent,
              lang: device.kitchenLang,
              restaurantName: device.credentials?.restaurantName ?? '',
            );
        final PrintResult res = await ref
            .read(printerServiceProvider)
            .send(printer: p, bytes: bytes);
        if (!res.ok) printErrors.add(res.error ?? 'unknown error');
      }
      if (!mounted) return;
      scaffold.showSnackBar(SnackBar(
        content: Text(printErrors.isEmpty
            ? 'Sent to kitchen · ${sent.orderNumber}'
            : 'Sent — print issues: ${printErrors.join("; ")}',),
      ),);
    } on ApiException catch (e) {
      if (mounted) {
        scaffold.showSnackBar(SnackBar(content: Text('Send failed: ${e.message}')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    // NavigationRail expects an int index. "All" sits at index 0; categories
    // start at index 1.
    final int selectedIndex = selectedId == null
        ? 0
        : 1 + categories.indexWhere((Category c) => c.id == selectedId).clamp(0, categories.length);
    return NavigationRail(
      labelType: NavigationRailLabelType.all,
      selectedIndex: selectedIndex,
      onDestinationSelected: (int i) {
        if (i == 0) {
          onSelect(null);
        } else {
          onSelect(categories[i - 1].id);
        }
      },
      destinations: <NavigationRailDestination>[
        const NavigationRailDestination(
          icon: Icon(Icons.apps_outlined),
          selectedIcon: Icon(Icons.apps),
          label: Text('All'),
        ),
        for (final Category c in categories)
          NavigationRailDestination(
            icon: const Icon(Icons.label_outline),
            selectedIcon: const Icon(Icons.label),
            label: Text(c.name),
          ),
      ],
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
