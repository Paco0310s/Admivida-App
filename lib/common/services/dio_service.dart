import 'dart:io';
import 'dart:convert';
import 'package:admivida/common/enums/app_failure_enum.dart';
import 'package:dio/dio.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/logging/app_logger.dart';
import 'package:admivida/common/services/storage_service.dart';
import 'package:admivida/common/utils/either.dart';
import 'package:admivida/common/services/isar_cache_service.dart';
import 'package:admivida/common/services/connectivity_service.dart';

class DioService {
  static final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: AppConfig.baseUrl,
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
            sendTimeout: AppConfig.sendTimeout,
            // headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              final isPublicEndpoint = AppConfig.publicEndpoints.any((endpoint) => options.path.contains(endpoint));

              if (!isPublicEndpoint) {
                final token = StorageService.getString(AppConfig.accessTokenKey);
                if (token != null) {
                  options.headers['Authorization'] = 'Bearer $token';
                }
              }
              return handler.next(options);
            },
          ),
        );

  /// Processes Dio exceptions and returns the most precise specific user-friendly failure message.
  static EitherUtil<HttpFailure, T> _handleError<T>(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        AppLogger.warning('Connection timeout: ${error.message}', error: error, stackTrace: error.stackTrace);
        return EitherUtil.failure(HttpFailure.connectionTimeout());

      case DioExceptionType.sendTimeout:
        AppLogger.warning('Send timeout: ${error.message}', error: error, stackTrace: error.stackTrace);
        return EitherUtil.failure(HttpFailure.sendTimeout());

      case DioExceptionType.receiveTimeout:
        AppLogger.warning('Receive timeout: ${error.message}', error: error, stackTrace: error.stackTrace);
        return EitherUtil.failure(HttpFailure.receiveTimeout());

      case DioExceptionType.connectionError:
        AppLogger.warning('Connection error: ${error.message}', error: error, stackTrace: error.stackTrace);
        return EitherUtil.failure(HttpFailure.connectionError());

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final responseData = error.response?.data;

        // Define standard default fallback message
        final String defaultMessage = '${AppTexts.errorServerResponse} (Status code: $statusCode)';
        String finalMessage = defaultMessage;

        // Parse explicit structures sent from our NestJS backend error handling system
        if (responseData != null && responseData is Map<String, dynamic>) {
          final errorCode = responseData['errorCode'] as String?;
          final serverMessage = responseData['message'] as String?;

          // 1. Highest Priority: Try to map specific server error code to local clean frontend translations
          if (errorCode != null && errorCode.isNotEmpty) {
            finalMessage = AppFailure.fromCode(errorCode).message;
            if (AppFailure.fromCode(errorCode) == AppFailure.unknownError) finalMessage = serverMessage ?? AppFailure.unknownError.message;
          }
          // 2. Second Priority: If no local text match is found, fallback to explicit server raw message
          else if (serverMessage != null && serverMessage.isNotEmpty) {
            finalMessage = serverMessage;
          }
        }
        // 3. Third Priority: Handle plain string responses or raw native message structures
        else if (responseData is String && responseData.isNotEmpty) {
          finalMessage = responseData;
        } else if (error.message != null && error.message!.isNotEmpty) {
          finalMessage = error.message!;
        }

        AppLogger.warning('Bad Response [$statusCode]: $finalMessage', error: error, stackTrace: error.stackTrace);
        return EitherUtil.failure(HttpFailure.serverError(statusCode, finalMessage));

      case DioExceptionType.cancel:
        AppLogger.warning('Request cancelled: ${error.message}', error: error, stackTrace: error.stackTrace);
        return EitherUtil.failure(HttpFailure.cancelled(AppTexts.cancelledError));

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          AppLogger.warning('SocketException identified: ${error.message}', error: error, stackTrace: error.stackTrace);
          return EitherUtil.failure(HttpFailure.connectionError());
        }

        AppLogger.error('Unexpected unclassified Dio error: ${error.message}', error: error, stackTrace: error.stackTrace);
        return EitherUtil.failure(HttpFailure.unexpectedError(error.message ?? AppTexts.unknownError));

      default:
        AppLogger.error('Unhandled Dio error type: ${error.type}, message: ${error.message}', error: error, stackTrace: error.stackTrace);
        return EitherUtil.failure(HttpFailure.unexpectedError(error.message ?? AppTexts.unknownError));
    }
  }

  /// Helper to detect if the error is related to network issues (For GET fallback)
  static bool _isNetworkError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError ||
        (error.type == DioExceptionType.unknown && error.error is SocketException);
  }

  // =========================================================================
  // READ METHODS (GET) - Allow requests to attempt, fallback to Cache on fail
  // =========================================================================

  static Future<EitherUtil<HttpFailure, T>> get<T>(String url, T Function(Map<String, dynamic>) fromJson, {Map<String, dynamic>? queryParameters}) async {
    final cacheKey = 'GET_$url${queryParameters != null ? jsonEncode(queryParameters) : ""}';

    try {
      AppLogger.info('GET Request: $url ${queryParameters != null ? "with params: $queryParameters" : ""}');

      final response = await _dio.get(url, queryParameters: queryParameters);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;

        // Save the successful response to Isar cache for offline fallback
        await IsarCacheService.saveCache(cacheKey, jsonEncode(data));

        final result = fromJson(data);
        return EitherUtil.success(result);
      } else {
        return EitherUtil.failure(HttpFailure.serverError(response.statusCode ?? 0, AppTexts.errorServerResponse));
      }
    } on DioException catch (error) {
      if (_isNetworkError(error)) {
        // Read from Isar cache if network error occurs
        final cachedString = await IsarCacheService.getCache(cacheKey);
        if (cachedString != null) {
          AppLogger.info('🌐 OFFLINE MODE: Serving local ISAR cache for GET $url');
          final cachedData = jsonDecode(cachedString) as Map<String, dynamic>;
          return EitherUtil.success(fromJson(cachedData));
        }
      }
      return _handleError<T>(error);
    } catch (error) {
      AppLogger.error('Unexpected error in GET: $error');
      return EitherUtil.failure(HttpFailure.unexpectedError(error.toString()));
    }
  }

  static Future<EitherUtil<HttpFailure, List<T>>> getList<T>(
    String url,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final cacheKey = 'GET_LIST_$url${queryParameters != null ? jsonEncode(queryParameters) : ""}';

    try {
      AppLogger.info('GET LIST Request: $url ${queryParameters != null ? "with params: $queryParameters" : ""}');

      final response = await _dio.get(url, queryParameters: queryParameters);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> rawList = response.data as List<dynamic>;

        // Save the successful response to Isar cache for offline fallback
        await IsarCacheService.saveCache(cacheKey, jsonEncode(rawList));

        final List<T> resultList = rawList.map((jsonItem) => fromJson(jsonItem as Map<String, dynamic>)).toList();
        return EitherUtil.success(resultList);
      } else {
        return EitherUtil.failure(HttpFailure.serverError(response.statusCode ?? 0, AppTexts.errorServerResponse));
      }
    } on DioException catch (error) {
      if (_isNetworkError(error)) {
        // Read from Isar cache if network error occurs
        final cachedString = await IsarCacheService.getCache(cacheKey);
        if (cachedString != null) {
          AppLogger.info('🌐 OFFLINE MODE: Serving local ISAR cache for GET LIST $url');
          final List<dynamic> rawList = jsonDecode(cachedString) as List<dynamic>;
          final List<T> resultList = rawList.map((jsonItem) => fromJson(jsonItem as Map<String, dynamic>)).toList();
          return EitherUtil.success(resultList);
        }
      }
      return _handleError<List<T>>(error);
    } catch (error) {
      AppLogger.error('Unexpected error in GET LIST: $error');
      return EitherUtil.failure(HttpFailure.unexpectedError(error.toString()));
    }
  }

  // =========================================================================
  // WRITE METHODS - Protected by Pre-flight Internet Check
  // =========================================================================

  static Future<EitherUtil<HttpFailure, T>> post<T>(String url, Map<String, dynamic> data, T Function(Map<String, dynamic>) fromJson) async {
    if (!await ConnectivityService.hasInternet()) {
      AppLogger.warning('POST blocked: No internet connection for $url');
      return EitherUtil.failure(HttpFailure.connectionError());
    }

    try {
      AppLogger.info('POST Request: $url, Data: $data');

      final response = await _dio.post(url, data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data as Map<String, dynamic>;
        AppLogger.info('Server response JSON: $responseData');
        final result = fromJson(responseData);
        return EitherUtil.success(result);
      } else {
        return EitherUtil.failure(HttpFailure.serverError(response.statusCode ?? 0, AppTexts.errorServerResponse));
      }
    } on DioException catch (error) {
      return _handleError<T>(error);
    } catch (error) {
      AppLogger.error('Unexpected error in POST: $error');
      return EitherUtil.failure(HttpFailure.unexpectedError(error.toString()));
    }
  }

  static Future<EitherUtil<HttpFailure, T>> put<T>(
    String url,
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (!await ConnectivityService.hasInternet()) {
      AppLogger.warning('PUT blocked: No internet connection for $url');
      return EitherUtil.failure(HttpFailure.connectionError());
    }

    try {
      final queryLog = queryParameters != null ? ', QueryParams: $queryParameters' : '';
      AppLogger.info('PUT Request: $url$queryLog, Data: $data');

      final response = await _dio.put(url, data: data, queryParameters: queryParameters);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = (response.data == null || response.data == '') ? <String, dynamic>{} : response.data as Map<String, dynamic>;

        final result = fromJson(responseData);
        return EitherUtil.success(result);
      } else {
        return EitherUtil.failure(HttpFailure.serverError(response.statusCode ?? 0, AppTexts.errorServerResponse));
      }
    } on DioException catch (error) {
      return _handleError<T>(error);
    } catch (error) {
      AppLogger.error('Unexpected error in PUT: $error');
      return EitherUtil.failure(HttpFailure.unexpectedError(error.toString()));
    }
  }

  static Future<EitherUtil<HttpFailure, T>> patch<T>(
    String url,
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (!await ConnectivityService.hasInternet()) {
      AppLogger.warning('PATCH blocked: No internet connection for $url');
      return EitherUtil.failure(HttpFailure.connectionError());
    }

    try {
      final queryLog = queryParameters != null ? ', QueryParams: $queryParameters' : '';
      AppLogger.info('PATCH Request: $url$queryLog, Data: $data');

      final response = await _dio.patch(url, data: data, queryParameters: queryParameters);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = (response.data == null || response.data == '') ? <String, dynamic>{} : response.data as Map<String, dynamic>;

        final result = fromJson(responseData);
        return EitherUtil.success(result);
      } else {
        return EitherUtil.failure(HttpFailure.serverError(response.statusCode ?? 0, AppTexts.errorServerResponse));
      }
    } on DioException catch (error) {
      AppLogger.error('STATUS CODE: ${error.response?.statusCode}');
      AppLogger.error('ERROR DATA: ${error.response?.data}');
      return _handleError<T>(error);
    } catch (error) {
      AppLogger.error('Unexpected error in PATCH: $error');
      return EitherUtil.failure(HttpFailure.unexpectedError(error.toString()));
    }
  }

  static Future<EitherUtil<HttpFailure, bool>> delete(String url) async {
    if (!await ConnectivityService.hasInternet()) {
      AppLogger.warning('DELETE blocked: No internet connection for $url');
      return EitherUtil.failure(HttpFailure.connectionError());
    }

    try {
      AppLogger.info('DELETE Request: $url');

      final response = await _dio.delete(url);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return EitherUtil.success(true);
      } else {
        return EitherUtil.failure(HttpFailure.serverError(response.statusCode ?? 0, AppTexts.errorServerResponse));
      }
    } on DioException catch (error) {
      return _handleError<bool>(error);
    } catch (error) {
      AppLogger.error('Unexpected error in DELETE: $error');
      return EitherUtil.failure(HttpFailure.unexpectedError(error.toString()));
    }
  }

  /// Uploads a file using multipart/form-data.
  static Future<EitherUtil<HttpFailure, T>> uploadFile<T>(
    String url, {
    required String filePath,
    required String fileKey,
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? extraFields,
  }) async {
    if (!await ConnectivityService.hasInternet()) {
      AppLogger.warning('UPLOAD blocked: No internet connection for $url');
      return EitherUtil.failure(HttpFailure.connectionError());
    }

    try {
      AppLogger.info('UPLOAD Request: $url with file: $filePath');

      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({fileKey: await MultipartFile.fromFile(filePath, filename: fileName), ...?extraFields});

      final response = await _dio.post(
        url,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final result = fromJson(data);
        return EitherUtil.success(result);
      } else {
        return EitherUtil.failure(HttpFailure.serverError(response.statusCode ?? 0, AppTexts.errorServerResponse));
      }
    } on DioException catch (error) {
      return _handleError<T>(error);
    } catch (error) {
      AppLogger.error('Unexpected error in UPLOAD: $error');
      return EitherUtil.failure(HttpFailure.unexpectedError(error.toString()));
    }
  }
}
