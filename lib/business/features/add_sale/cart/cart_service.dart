import 'package:admivida/business/features/add_sale/cart/models/create_sale_dto.dart';
import 'package:admivida/business/features/add_sale/models/business_client_model.dart';
import 'package:admivida/business/features/sales/models/sale_model.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/services/dio_service.dart';
import 'package:admivida/common/utils/either.dart';
import 'package:admivida/common/constants/app_config.dart';

class CartService {
  static Future<EitherUtil<HttpFailure, List<BusinessClientModel>>> getClients(String businessId) async {
    final response = await DioService.getList<BusinessClientModel>(AppConfig.getBusinessClientsEndpoint(businessId), BusinessClientModel.fromJson);

    return response.when((failure) => EitherUtil.failure(failure), (clients) => EitherUtil.success(clients));
  }

  /// Creates a new sale by sending the provided [CreateSaleDto] to the backend API.
  static Future<EitherUtil<HttpFailure, SaleModel>> createSale(CreateSaleDto dto) async {
    return await DioService.post<SaleModel>(AppConfig.createSaleEndpoint, dto.toJson(), (data) => SaleModel.fromJson(data));
  }
}
