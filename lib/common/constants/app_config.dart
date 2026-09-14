class AppConfig {
  // Base URLs
  static const String baseUrl = 'http://localhost:7100/api/v1';
  // static const String baseUrl = 'http://192.168.1.14:3000/api/v1';
  static const String baseServerUrl = 'http://localhost:7100';

  // App version code
  static const int appVersionCode = 1;

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
  static String accountsBusinessEndpoint(String? businessId) => '/accounts/business/$businessId';
  static String accountsUserEndpoint(String? userId) => '/accounts/user/$userId';
  static const String paymentMethodsEndpoint = '/payment-methods';
  static String transactionsEndpoint = '/transactions';
  static String updateStockProductVariantEndpoint(String variantId) => '/product-variants/stock/$variantId';
  static String createProductEndpoint = '/products';
  static String updateProductEndpoint(String productId) => '/products/fromBusiness/$productId';
  static String getProductByIdEndpoint(String productId, String businessId) => '/products/$productId/business/$businessId';
  static String getPendingCommissionsEndpoint(String businessId) => '/commission-payments/pending/$businessId';
  static String getBusinessSellersEndpoint(String businessId) => '/users/businesses/$businessId/sellers';
  static String getBusinessClientsEndpoint(String businessId) => '/users/businesses/$businessId/clients';
  static String productVariantScanEndpoint(String sku) => '/product-variants/scan/$sku';
  static String createSaleEndpoint = '/sales';
  static String createCommissionPaymentEndpoint(String businessId) => '/commission-payments/$businessId';
  static String getCommissionPaymentHistoryBusinessEndpoint(String businessId) => '/commission-payments/history/$businessId';
  static String getCommissionPaymentMyHistoryEndpoint(String businessId) => '/commission-payments/my-history/$businessId';
  static String updateBusinessEndpoint(String businessId) => '/businesses/$businessId';

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
