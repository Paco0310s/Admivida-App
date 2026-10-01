import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/models/file_responde_dto.dart';
import 'package:admivida/common/services/dio_service.dart';
import 'package:admivida/common/utils/either.dart';
import 'package:image_picker/image_picker.dart';

class FileService {
  /// Uploads an image file to NestJS and returns the FileResponseDto containing the fileId.
  static Future<EitherUtil<HttpFailure, FileResponseDto>> uploadImage(XFile file) async {
    return DioService.uploadFile(
      AppConfig.fileUploadEndpoint,
      fileBytes: await file.readAsBytes(),
      fileName: file.name,
      fileKey: 'file',
      fromJson: (json) => FileResponseDto.fromJson(json),
    );
  }
}
