import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/models/file_responde_dto.dart';
import 'package:admivida/common/services/dio_service.dart';
import 'package:admivida/common/utils/either.dart';

class FileService {
  /// Uploads an image file to NestJS and returns the FileResponseDto containing the fileId.
  static Future<EitherUtil<HttpFailure, FileResponseDto>> uploadImage(String filePath) async {
    return await DioService.uploadFile(AppConfig.fileUploadEndpoint, filePath: filePath, fileKey: 'file', fromJson: (json) => FileResponseDto.fromJson(json));
  }
}
