import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/router.dart';
import '../models/printer.dart';
import '../services/printer_service.dart';
import '../state/device_state.dart';
import '../state/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DeviceState device = ref.watch(deviceStateProvider);
    final AsyncValue<List<Printer>> printersAsync =
        ref.watch(activeStorePrintersProvider);

    final List<Printer> printers = printersAsync.maybeWhen(
      data: (List<Printer> p) => p,
      orElse: () => <Printer>[],
    );
    final Iterable<Printer> receiptPrinters = printers
        .where((Printer p) => p.printerType == PrinterType.receipt && p.isActive);
    final Iterable<Printer> kitchenPrinters = printers
        .where((Printer p) => p.printerType == PrinterType.kitchen && p.isActive);

    Printer? findById(String? id, Iterable<Printer> pool) {
      if (id == null || id.isEmpty) return null;
      for (final Printer p in pool) {
        if (p.id == id) return p;
      }
      return null;
    }

    final Printer? receiptPrinter =
        findById(device.receiptPrinterId, receiptPrinters);
    final Printer? kitchenPrinter =
        findById(device.kitchenPrinterId, kitchenPrinters);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _Section(
            title: 'Active store',
            child: ListTile(
              title: Text(device.credentials?.storeId.isEmpty ?? true
                  ? 'Not set'
                  : device.credentials!.storeId,),
              subtitle: const Text(
                'Re-pair tablet from device-setup to change store',
              ),
            ),
          ),
          _PrinterPickerSection(
            title: 'Receipt printer',
            choices: receiptPrinters.toList(),
            selected: receiptPrinter,
            onChanged: (Printer? p) {
              ref
                  .read(deviceStateProvider.notifier)
                  .setPrinters(receiptId: p?.id ?? '');
            },
            languageLabel: 'Receipt language',
            language: device.receiptLang,
            onLanguageChanged: (NameLang v) =>
                ref.read(deviceStateProvider.notifier).setLang(receipt: v),
          ),
          _PrinterPickerSection(
            title: 'Kitchen printer',
            choices: kitchenPrinters.toList(),
            selected: kitchenPrinter,
            onChanged: (Printer? p) {
              ref
                  .read(deviceStateProvider.notifier)
                  .setPrinters(kitchenId: p?.id ?? '');
            },
            languageLabel: 'Kitchen language',
            language: device.kitchenLang,
            onLanguageChanged: (NameLang v) =>
                ref.read(deviceStateProvider.notifier).setLang(kitchen: v),
          ),
          _Section(
            title: 'Cash drawer',
            child: ListTile(
              title: Text(
                receiptPrinter == null
                    ? 'Pick a receipt printer to enable the drawer'
                    : 'Linked to ${receiptPrinter.name}',
              ),
              trailing: TextButton(
                onPressed: receiptPrinter == null
                    ? null
                    : () => _testDrawer(context, ref, receiptPrinter),
                child: const Text('Test drawer kick'),
              ),
            ),
          ),
          _Section(
            title: 'Customer display',
            child: Column(
              children: <Widget>[
                ListTile(
                  title: Text(device.customerDisplayIp == null ||
                          device.customerDisplayIp!.isEmpty
                      ? 'Not paired'
                      : 'Paired: ${device.customerDisplayIp}',),
                  trailing: const Text('TODO phase 5'),
                ),
                _LanguageRadios(
                  label: 'Display language',
                  value: device.displayLang,
                  onChanged: (NameLang v) =>
                      ref.read(deviceStateProvider.notifier).setLang(display: v),
                ),
              ],
            ),
          ),
          _Section(
            title: 'Tablet identity',
            child: ListTile(
              title: Text(
                device.credentials == null
                    ? 'Not paired'
                    : '${device.credentials!.role} · ${device.credentials!.restaurantName}',
              ),
              trailing: TextButton(
                onPressed: () => _wipeDevice(context, ref),
                child: const Text('Sign out & wipe'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testDrawer(
      BuildContext context, WidgetRef ref, Printer receipt,) async {
    final ScaffoldMessengerState m = ScaffoldMessenger.of(context);
    final PrintResult res = await ref.read(drawerServiceProvider).kick(receipt);
    m.showSnackBar(SnackBar(
      content: Text(res.ok ? 'Drawer kicked' : res.error ?? 'Drawer kick failed'),
    ),);
  }

  Future<void> _wipeDevice(BuildContext context, WidgetRef ref) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: const Text('Wipe this tablet?'),
        content: const Text(
          'All cashier credentials and device pairing will be removed. The tablet will need to be paired again.',
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Wipe')),
        ],
      ),
    );
    if (ok ?? false) {
      await ref.read(deviceStateProvider.notifier).wipe();
      ref.read(sessionStateProvider.notifier).signOut();
      ref.invalidate(cashierEntriesProvider);
      if (context.mounted) context.go(TillRoutes.deviceSetup);
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          Card(child: child),
        ],
      ),
    );
  }
}

class _PrinterPickerSection extends StatelessWidget {
  const _PrinterPickerSection({
    required this.title,
    required this.choices,
    required this.selected,
    required this.onChanged,
    required this.languageLabel,
    required this.language,
    required this.onLanguageChanged,
  });

  final String title;
  final List<Printer> choices;
  final Printer? selected;
  final ValueChanged<Printer?> onChanged;
  final String languageLabel;
  final NameLang language;
  final ValueChanged<NameLang> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: title,
      child: Column(
        children: <Widget>[
          if (choices.isEmpty)
            const ListTile(
              title: Text('No printers of this type configured'),
              subtitle: Text('Add one in the admin web'),
            )
          else
            ListTile(
              title: Text(selected?.name ?? 'Not set'),
              subtitle: selected == null
                  ? null
                  : Text('${selected!.ipAddress}:${selected!.port}'),
              trailing: DropdownButton<String>(
                value: selected?.id ?? '',
                hint: const Text('Pick'),
                onChanged: (String? id) {
                  if (id == null || id.isEmpty) {
                    onChanged(null);
                    return;
                  }
                  for (final Printer p in choices) {
                    if (p.id == id) {
                      onChanged(p);
                      return;
                    }
                  }
                },
                items: <DropdownMenuItem<String>>[
                  const DropdownMenuItem<String>(value: '', child: Text('None')),
                  for (final Printer p in choices)
                    DropdownMenuItem<String>(value: p.id, child: Text(p.name)),
                ],
              ),
            ),
          _LanguageRadios(
            label: languageLabel,
            value: language,
            onChanged: onLanguageChanged,
          ),
        ],
      ),
    );
  }
}

class _LanguageRadios extends StatelessWidget {
  const _LanguageRadios({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final NameLang value;
  final ValueChanged<NameLang> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          SegmentedButton<NameLang>(
            segments: const <ButtonSegment<NameLang>>[
              ButtonSegment<NameLang>(value: NameLang.en, label: Text('English')),
              ButtonSegment<NameLang>(value: NameLang.vi, label: Text('Vietnamese')),
              ButtonSegment<NameLang>(value: NameLang.both, label: Text('Both')),
            ],
            selected: <NameLang>{value},
            onSelectionChanged: (Set<NameLang> s) => onChanged(s.first),
          ),
        ],
      ),
    );
  }
}
