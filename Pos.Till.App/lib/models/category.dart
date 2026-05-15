import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

/// Plan phase 7 adds [nameLocalized] + [altLanguageCode] to the API. Until the
/// migration lands those fields read as null and the till behaves single-lang.
@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    String? nameLocalized,
    String? altLanguageCode,
    required int displayOrder,
    required bool isActive,
    required DateTime createdAt,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}
