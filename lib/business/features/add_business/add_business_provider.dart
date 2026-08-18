import 'package:admivida/business/features/add_business/add_business_service.dart';
import 'package:admivida/business/features/add_business/models/business_category_model.dart';
import 'package:admivida/business/features/add_business/models/create_business_dto.dart';
import 'package:admivida/business/features/businesses/businesses_provider.dart';
import 'package:admivida/business/models/business_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_business_provider.g.dart';

@riverpod
class CreateBusiness extends _$CreateBusiness {
  /// Initial state setup. Defaults to null as no business creation
  /// request has been executed yet on build time.
  @override
  FutureOr<BusinessModel?> build() {
    return null;
  }

  /// Handles the HTTP POST request to register a new business entity in NestJS.
  Future<void> submit(CreateBusinessDto dto) async {
    // 1. Set the state to loading to inform the UI layer (e.g., disable submit buttons)
    state = const AsyncValue.loading();

    // 2. Perform the API call via the static business service
    final result = await AddBusinessService.createBusiness(dto);

    // 3. Process the domain result using EitherUtil pattern
    result.when(
      (failure) {
        // Assign the failure error state to be captured by ref.listen in the presentation layer
        state = AsyncValue.error(failure, StackTrace.current);
      },
      (newBusiness) {
        // Successfully update state with the freshly created business entity
        state = AsyncValue.data(newBusiness);

        // Invalidate the global businesses list provider to trigger an automatic
        // background re-fetch, keeping the dashboard hub state fully synchronized.
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
