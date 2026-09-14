import 'package:admivida/business/features/add_business/add_business_service.dart';
import 'package:admivida/business/features/add_business/models/business_category_model.dart';
import 'package:admivida/business/features/add_business/models/create_business_dto.dart';
import 'package:admivida/business/features/add_business/models/update_business_dto.dart';
import 'package:admivida/business/features/businesses/businesses_provider.dart';
import 'package:admivida/business/models/business_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_business_provider.g.dart';

@riverpod
class CreateOrUpdateBusiness extends _$CreateOrUpdateBusiness {
  @override
  FutureOr<BusinessModel?> build() {
    return null;
  }

  /// Handles both POST (create) and PATCH (update) requests.
  Future<void> submit({CreateBusinessDto? createDto, UpdateBusinessDto? updateDto, String? businessId}) async {
    state = const AsyncValue.loading();

    final isUpdate = businessId != null && updateDto != null;

    final result = isUpdate ? await AddBusinessService.updateBusiness(businessId, updateDto) : await AddBusinessService.createBusiness(createDto!);

    result.when(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
      (business) {
        state = AsyncValue.data(business);
        ref.invalidate(businessesListProvider);
      },
    );
  }
}

@riverpod
class BusinessCategories extends _$BusinessCategories {
  /// Initial fetch of business categories from the API.
  @override
  Future<List<BusinessCategoryModel>> build() async {
    return _fetchFromNetwork();
  }

  /// Internal method to trigger the HTTP GET call via DioService.
  Future<List<BusinessCategoryModel>> _fetchFromNetwork() async {
    final result = await AddBusinessService.getBusinessCategories();
    return result.when((failure) => throw failure, (categories) => categories);
  }

  /// Allows manually refreshing the categories list if needed.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchFromNetwork());
  }
}
