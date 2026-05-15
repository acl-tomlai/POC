import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/secure_credentials.dart';

/// Per-surface language preference for product names.
enum NameLang { en, vi, both }

NameLang nameLangFromString(String? v) {
  switch (v) {
    case 'vi':
      return NameLang.vi;
    case 'both':
      return NameLang.both;
    default:
      return NameLang.en;
  }
}

String nameLangToString(NameLang v) {
  switch (v) {
    case NameLang.vi:
      return 'vi';
    case NameLang.both:
      return 'both';
    case NameLang.en:
      return 'en';
  }
}

/// Device-wide configuration loaded from secure_storage + shared_preferences.
class DeviceState {
  const DeviceState({
    this.credentials,
    this.receiptLang = NameLang.en,
    this.kitchenLang = NameLang.en,
    this.displayLang = NameLang.en,
    this.receiptPrinterId,
    this.kitchenPrinterId,
  });

  final DeviceCredentials? credentials;
  final NameLang receiptLang;
  final NameLang kitchenLang;
  final NameLang displayLang;
  final String? receiptPrinterId;
  final String? kitchenPrinterId;

  bool get isPaired => credentials != null;

  DeviceState copyWith({
    DeviceCredentials? credentials,
    bool clearCredentials = false,
    NameLang? receiptLang,
    NameLang? kitchenLang,
    NameLang? displayLang,
    String? receiptPrinterId,
    String? kitchenPrinterId,
  }) {
    return DeviceState(
      credentials: clearCredentials ? null : (credentials ?? this.credentials),
      receiptLang: receiptLang ?? this.receiptLang,
      kitchenLang: kitchenLang ?? this.kitchenLang,
      displayLang: displayLang ?? this.displayLang,
      receiptPrinterId: receiptPrinterId ?? this.receiptPrinterId,
      kitchenPrinterId: kitchenPrinterId ?? this.kitchenPrinterId,
    );
  }
}

class DeviceStateNotifier extends StateNotifier<DeviceState> {
  DeviceStateNotifier(this._secure) : super(const DeviceState()) {
    _load();
  }

  final SecureCredentialsService _secure;

  Future<void> _load() async {
    final DeviceCredentials? c = await _secure.readDevice();
    if (c != null) state = state.copyWith(credentials: c);
  }

  Future<void> setCredentials(DeviceCredentials c) async {
    await _secure.saveDevice(c);
    state = state.copyWith(credentials: c);
  }

  Future<void> wipe() async {
    await _secure.wipeDevice();
    state = const DeviceState();
  }

  void setLang({NameLang? receipt, NameLang? kitchen, NameLang? display}) {
    state = state.copyWith(
      receiptLang: receipt,
      kitchenLang: kitchen,
      displayLang: display,
    );
  }

  void setPrinters({String? receiptId, String? kitchenId}) {
    state = state.copyWith(
      receiptPrinterId: receiptId,
      kitchenPrinterId: kitchenId,
    );
  }
}
