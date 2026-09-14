import 'package:admivida/business/features/add_business/models/business_category_model.dart';
import 'package:admivida/business/features/add_business/models/create_business_dto.dart';
import 'package:admivida/business/features/add_business/models/update_business_dto.dart';
import 'package:admivida/business/models/business_model.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/services/dio_service.dart';
import 'package:admivida/common/utils/either.dart';

class AddBusinessService {
  static Future<EitherUtil<HttpFailure, BusinessModel>> createBusiness(CreateBusinessDto createBusinessDto) async {
    return await DioService.post(AppConfig.createBusinessEndpoint, createBusinessDto.toJson(), (json) => BusinessModel.fromJson(json));
  }

  static Future<EitherUtil<HttpFailure, BusinessModel>> updateBusiness(String businessId, UpdateBusinessDto dto) async {
    return DioService.patch<BusinessModel>(AppConfig.updateBusinessEndpoint(businessId), dto.toJson(), (json) => BusinessModel.fromJson(json));
  }

  static Future<EitherUtil<HttpFailure, List<BusinessCategoryModel>>> getBusinessCategories() async {
    return await DioService.getList(AppConfig.businessCategoriesEndpoint, (json) => BusinessCategoryModel.fromJson(json));
  }
}
