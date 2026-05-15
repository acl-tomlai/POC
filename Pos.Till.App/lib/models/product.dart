import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

/// Plan phase 7 adds [nameLocalized] + [altLanguageCode] to the API. Until the
/// migration lands those fields read as null and the till behaves single-lang.
@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String categoryId,
    required String categoryName,
    required String name,
    String? nameLocalized,
    String? altLanguageCode,
    String? description,
    String? sku,
    String? barcode,
    required double price,
    double? costPrice,
    String? imageUrl,
    required bool isActive,
    required DateTime createdAt,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
