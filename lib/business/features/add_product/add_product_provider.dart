import 'package:admivida/business/features/add_product/add_product_service.dart';
import 'package:admivida/business/features/add_product/models/product_category_model.dart';
import 'package:admivida/business/features/add_product/models/product_type_model.dart';
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
