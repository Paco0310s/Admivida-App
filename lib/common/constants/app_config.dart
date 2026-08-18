class AppConfig {
  // Base URLs
  static const String baseUrl = 'http://localhost:3000/api/v1';
  // static const String baseUrl = 'http://192.168.1.39:3000/api/v1';
  static const String baseServerUrl = 'http://localhost:3000';

  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String profileEndpoint = '/auth/profile';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String logoutEndpoint = '/auth/logout';
  static const String myBusinessesEndpoint = '/businesses/my-list';
  static const String createBusinessEndpoint = '/businesses';
  static const String fileUploadEndpoint = '/files/upload';
  static const String businessCategoriesEndpoint = '/business-categories';
  static String productsTenantEndpoint(String businessId) => '/products/business/$businessId';
  static const String productTypesEndpoint = '/product-types';
  static String productCategoriesEndpoint(String businessId) => '/product-categories/$businessId';
  static String salesTenantEndpoint(String businessId) => '/sales/business/$businessId';
  static String transactionsTenantEndpoint = '/transactions/business';

  // Public endpoints (no authentication required)
  static const List<String> publicEndpoints = ['/auth/login', '/auth/register', '/auth/refresh'];

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  static const Duration sendTimeout = Duration(seconds: 10);

  // Storage keys
  static const String accessTokenKey = 'accessToken';
  static const String refreshTokenKey = 'refreshToken';
  static const String rolesKey = 'roles';
  static const String currentPlatformRoleKey = 'currentPlatformRole';
}
