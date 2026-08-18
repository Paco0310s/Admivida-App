import 'package:admivida/business/models/business_model.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/services/dio_service.dart';
import 'package:admivida/common/utils/either.dart';

class BusinessesService {
  static Future<EitherUtil<HttpFailure, List<BusinessModel>>> getMyBusinesses() async {
    return await DioService.getList(AppConfig.myBusinessesEndpoint, (json) => BusinessModel.fromJson(json));
  }
}
