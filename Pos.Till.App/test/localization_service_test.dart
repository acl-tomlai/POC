import 'package:flutter_test/flutter_test.dart';
import 'package:pos_till_app/services/localization_service.dart';
import 'package:pos_till_app/state/device_state.dart';

void main() {
  const LocalizationService svc = LocalizationService();

  group('LocalizationService.resolve', () {
    test('en always picks primary', () {
      expect(
        svc.resolve(name: 'Beef Pho', nameLocalized: 'Phở Bò', lang: NameLang.en),
        'Beef Pho',
      );
    });

    test('vi picks alt when present', () {
      expect(
        svc.resolve(name: 'Beef Pho', nameLocalized: 'Phở Bò', lang: NameLang.vi),
        'Phở Bò',
      );
    });

    test('vi falls back to primary when alt is null', () {
      expect(
        svc.resolve(name: 'Beef Pho', lang: NameLang.vi),
        'Beef Pho',
      );
    });

    test('vi falls back to primary when alt is empty/whitespace', () {
      expect(
        svc.resolve(name: 'Beef Pho', nameLocalized: '   ', lang: NameLang.vi),
        'Beef Pho',
      );
    });

    test('both joins with newline when alt is present', () {
      expect(
        svc.resolve(name: 'Beef Pho', nameLocalized: 'Phở Bò', lang: NameLang.both),
        'Beef Pho\nPhở Bò',
      );
    });

    test('both prints primary only when alt is missing', () {
      expect(
        svc.resolve(name: 'Beef Pho', lang: NameLang.both),
        'Beef Pho',
      );
    });
  });

  group('LocalizationService.splitBoth', () {
    test('round-trips a both-rendered string', () {
      final String rendered = svc.resolve(
        name: 'Beef Pho',
        nameLocalized: 'Phở Bò',
        lang: NameLang.both,
      );
      final ({String primary, String? alt}) parts = svc.splitBoth(rendered);
      expect(parts.primary, 'Beef Pho');
      expect(parts.alt, 'Phở Bò');
    });

    test('returns alt=null for a single-line rendered string', () {
      final ({String primary, String? alt}) parts = svc.splitBoth('Beef Pho');
      expect(parts.primary, 'Beef Pho');
      expect(parts.alt, isNull);
    });
  });
}
