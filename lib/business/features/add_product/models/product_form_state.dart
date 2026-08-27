import 'package:admivida/business/features/add_product/models/update_product_dto.dart';

class ProductFormState {
  final String? productId;
  final String name;
  final String unitOfMeasure;
  final List<UpdateProductVariantDto> variants;
  final bool isLoading;

  ProductFormState({this.productId, this.name = '', this.unitOfMeasure = 'PZ', this.variants = const [], this.isLoading = false});

  ProductFormState copyWith({String? productId, String? name, String? unitOfMeasure, List<UpdateProductVariantDto>? variants, bool? isLoading}) {
    return ProductFormState(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      variants: variants ?? this.variants,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
