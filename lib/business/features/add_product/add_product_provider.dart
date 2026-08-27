import 'package:admivida/business/features/add_product/add_product_service.dart';
import 'package:admivida/business/features/add_product/models/create_product_dto.dart';
import 'package:admivida/business/features/add_product/models/product_category_model.dart';
import 'package:admivida/business/features/add_product/models/product_form_state.dart';
import 'package:admivida/business/features/add_product/models/product_type_model.dart';
import 'package:admivida/business/features/add_product/models/update_product_dto.dart';
import 'package:admivida/business/features/products/models/product_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_product_provider.g.dart';

@riverpod
Future<List<ProductTypeModel>> productTypes(Ref ref) async {
  final result = await AddProductService.getProductTypes();

  return result.when((failure) => throw failure, (types) => types);
}

@riverpod
Future<List<ProductCategoryModel>> productCategories(Ref ref, String businessId) async {
  final result = await AddProductService.getTenantCategories(businessId);

  return result.when((failure) => throw failure, (categories) => categories);
}

@riverpod
class ProductForm extends _$ProductForm {
  @override
  ProductFormState build(ProductModel? initialProduct) {
    if (initialProduct != null) {
      // Edit Mode: Map existing variants to the DTO, including metadata and images
      final existingVariants = initialProduct.variants
          .map(
            (v) => UpdateProductVariantDto(
              id: v.id,
              sku: v.sku,
              barcode: v.barcode,
              name: v.name,
              purchasePrice: v.purchasePrice,
              salePrice: v.salePrice,
              wholesalePrice: v.wholesalePrice,
              wholesaleQuantity: v.wholesaleQuantity,
              stockQuantity: v.stockQuantity,
              minimumStock: v.minimumStock,
              maximumStock: v.maximumStock,
              attributes: v.attributes,
              // Map existing images (make sure to use img.fileId, not img.id for fileId)
              images: v.images.map((img) => UpdateProductImageDto(id: img.id, fileId: img.fileId, main: img.main)).toList(),
            ),
          )
          .toList();

      return ProductFormState(productId: initialProduct.id, name: initialProduct.name, unitOfMeasure: initialProduct.unitOfMeasure, variants: existingVariants);
    }

    // Creation Mode: Blank state with a default empty variant
    return ProductFormState(variants: [UpdateProductVariantDto(salePrice: 0.0)]);
  }

  // --- METHODS TO UPDATE STATE FROM UI ---

  void updateName(String name) => state = state.copyWith(name: name);

  // 💡 Helper to replace the entire variants list from the UI just before submitting
  void setVariants(List<UpdateProductVariantDto> newVariants) {
    state = state.copyWith(variants: newVariants);
  }

  void addVariant(UpdateProductVariantDto variant) {
    state = state.copyWith(variants: [...state.variants, variant]);
  }

  void updateVariant(int index, UpdateProductVariantDto updatedVariant) {
    final newVariants = List<UpdateProductVariantDto>.from(state.variants);
    newVariants[index] = updatedVariant;
    state = state.copyWith(variants: newVariants);
  }

  void removeVariant(int index) {
    final newVariants = List<UpdateProductVariantDto>.from(state.variants)..removeAt(index);
    state = state.copyWith(variants: newVariants);
  }

  // --- MAIN SUBMIT METHOD ---
  Future<bool> submit({
    required String businessId,
    required String productTypeId, // Needed for creation and update
    String? productCategoryId,
    String? description,
    bool isActive = true,
    required String unitOfMeasure, // Re-added to explicitly receive it from UI
    String? mainFileId, // Pass the uploaded main image ID from the UI
  }) async {
    // 1. Basic security validation (even if UI also validates)
    if (state.name.trim().isEmpty || state.variants.isEmpty) {
      return false;
    }

    // 2. Activate loading state
    state = state.copyWith(isLoading: true);

    try {
      if (state.productId == null) {
        // ------------------------
        // 🚀 CREATION MODE (POST)
        // ------------------------
        final createDto = CreateProductDto(
          businessId: businessId,
          productTypeId: productTypeId,
          productCategoryId: productCategoryId,
          name: state.name.trim(),
          description: description, // Mapped
          unitOfMeasure: unitOfMeasure, // Mapped
          isActive: isActive, // Mapped
          // Map main image if provided
          images: mainFileId != null ? [CreateProductImageDto(fileId: mainFileId, main: true)] : const [],
          // Convert generic variants to creation DTO, including images and attributes
          variants: state.variants
              .map(
                (v) => CreateProductVariantDto(
                  sku: v.sku,
                  barcode: v.barcode,
                  name: v.name,
                  purchasePrice: v.purchasePrice,
                  salePrice: v.salePrice ?? 0.0, // Ensure it is not null
                  wholesalePrice: v.wholesalePrice,
                  wholesaleQuantity: v.wholesaleQuantity,
                  stockQuantity: v.stockQuantity,
                  minimumStock: v.minimumStock,
                  maximumStock: v.maximumStock,
                  attributes: v.attributes,
                  // Convert UpdateProductImageDto back to CreateProductImageDto
                  images: v.images?.map((img) => CreateProductImageDto(fileId: img.fileId, main: img.main)).toList() ?? [],
                ),
              )
              .toList(),
        );

        // Call your Flutter service
        final result = await AddProductService.createProduct(createDto);

        return result.when((failure) => false, (success) => true);
      } else {
        // ------------------------
        // ✏️ EDIT MODE (PUT)
        // ------------------------
        final updateDto = UpdateProductDto(
          name: state.name.trim(),
          description: description, // Mapped
          isActive: isActive, // Mapped
          productTypeId: productTypeId, // Mapped
          productCategoryId: productCategoryId, // Mapped
          unitOfMeasure: unitOfMeasure, // Mapped
          variants: state.variants, // These are already UpdateProductVariantDto
          // Map main image for update if provided
          images: mainFileId != null ? [UpdateProductImageDto(fileId: mainFileId, main: true)] : const [],
        );

        final result = await AddProductService.updateProduct(productId: state.productId!, businessId: businessId, dto: updateDto);

        return result.when((failure) => false, (success) => true);
      }
    } catch (e) {
      // Catch any unexpected error
      return false;
    } finally {
      // 3. Deactivate loading state regardless of the outcome
      state = state.copyWith(isLoading: false);
    }
  }
}
