import 'package:admivida/business/features/businesses/businesses_dashoboard_service.dart';
import 'package:admivida/business/models/business_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'businesses_provider.g.dart';

@riverpod
class BusinessesList extends _$BusinessesList {
  @override
  Future<List<BusinessModel>> build() async {
    return _fetchFromNetwork();
  }

  Future<List<BusinessModel>> _fetchFromNetwork() async {
    final result = await BusinessesService.getMyBusinesses();

    return result.when((failure) => throw failure, (businesses) => businesses);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchFromNetwork());
  }
}
