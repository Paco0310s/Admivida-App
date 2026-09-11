import 'package:admivida/business/features/add_sale/add_sale_service.dart';
import 'package:admivida/business/features/add_sale/models/scanned_variant_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_sale_provider.g.dart';

@riverpod
Future<ScannedVariantModel> scannedVariant(Ref ref, String sku, String businessId) async {
  final result = await AddSaleService.scanProductVariant(sku: sku, businessId: businessId);
  return result.when((failure) => throw failure, (scannedVariant) => scannedVariant);
}
