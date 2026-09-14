import 'package:admivida/business/features/add_business/add_business_screen.dart';
import 'package:admivida/business/features/add_product/product_form_screen.dart';
import 'package:admivida/business/features/add_sale/add_sale_screen.dart';
import 'package:admivida/business/features/add_sale/cart/cart_screen.dart';
import 'package:admivida/business/features/add_sale/product_detail/product_detail_screen.dart';
import 'package:admivida/business/features/add_transaction/add_transactions_screen.dart';
import 'package:admivida/business/features/business_detail/business_detail_screen.dart';
import 'package:admivida/business/features/businesses/businesses_screen.dart';
import 'package:admivida/business/features/commission_payment_history/commission_payment_history_screen.dart';
import 'package:admivida/business/features/commission_payments/commission_payment_screen.dart';
import 'package:admivida/business/features/products/products_screen.dart';
import 'package:admivida/business/features/products/product_detail_screen.dart';
import 'package:admivida/business/features/products/models/product_model.dart';
import 'package:admivida/business/features/sales/models/sale_model.dart';
import 'package:admivida/business/features/sales/sale_detail_screen.dart';
import 'package:admivida/business/features/sales/sales_screen.dart';
import 'package:admivida/business/features/transactions/transactions_screen.dart';
import 'package:admivida/business/models/business_model.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/features/choose_platform_role/choose_platform_role_screen.dart';
import 'package:admivida/common/features/home/home_screen.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:admivida/common/features/forgot_password/forgot_password_screen.dart';
import 'package:admivida/common/features/sign_in/sign_in_screen.dart';
import 'package:admivida/common/features/sign_up/sign_up_screen.dart';
import 'package:admivida/common/features/offline/offline_screen.dart';
import 'package:admivida/common/features/splash/splash_screen.dart';
import 'package:admivida/common/features/status/status_screen.dart';
import 'routes.dart';

class AppRoutes {
  Map<String, Widget Function(BuildContext)> get routes {
    return {
      Routes.splash: (context) => const SplashScreen(),
      Routes.signIn: (context) => const SignInScreen(),
      Routes.offline: (context) => const OfflineScreen(),
      Routes.maintenance: (context) => const MaintenanceScreen(),
      Routes.updateRequired: (context) => const UpdateRequiredScreen(),
      Routes.signUp: (context) => const SignUpScreen(),
      Routes.forgotPassword: (context) => const ForgotPasswordScreen(),
      Routes.choosePlatformRole: (context) => const ChoosePlatformRoleScreen(),
      Routes.home: (context) => const HomeScreen(),
      Routes.businesses: (context) => const BusinessesScreen(),
      Routes.businessDetail: (context) {
        final business = ModalRoute.of(context)?.settings.arguments as BusinessModel?;
        return BusinessDetailScreen(
          business:
              business ?? BusinessModel(id: '', name: '', description: '', businessCategoryId: '', categoryName: '', isActive: true, createdAt: DateTime.now()),
        );
      },
      Routes.products: (context) {
        final businessId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
        return ProductsScreen(businessId: businessId);
      },
      Routes.productDetail: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return ProductDetailScreen(businessId: args['businessId'], productId: args['productId']);
      },
      Routes.createOrUpdateProduct: (context) {
        // 1. Get the arguments from the route settings
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

        // 2. Extract the businessId and product from the arguments
        final String businessId = args['businessId'] as String;
        final ProductModel? product = args['product'] as ProductModel?;

        return ProductFormScreen(businessId: businessId, product: product);
      },
      Routes.createOrUpdateBusinessScreen: (context) {
        final business = ModalRoute.of(context)?.settings.arguments as BusinessModel?;
        return CreateOrUpdateBusinessScreen(business: business);
      },
      Routes.addSale: (context) {
        final businessId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
        return AddSaleScreen(businessId: businessId);
      },
      Routes.sales: (context) {
        final businessId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
        return SalesScreen(businessId: businessId);
      },
      Routes.transactions: (context) {
        final businessId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
        return TransactionsScreen(businessId: businessId);
      },
      Routes.productDetailSale: (context) {
        final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final product =
            arguments?['product'] as ProductModel? ??
            ProductModel(
              id: '',
              name: '',
              unitOfMeasure: '',
              isActive: true,
              variants: [],
              images: [],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              businessId: '',
              productTypeId: '',
            );
        final businessId = arguments?['businessId'] as String? ?? '';
        return ProductDetailSaleScreen(product: product, businessId: businessId);
      },
      Routes.addTransaction: (context) {
        final businessId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
        return AddTransactionScreen(businessId: businessId);
      },
      Routes.saleDetail: (context) {
        final sale = ModalRoute.of(context)?.settings.arguments as SaleModel?;
        return SaleDetailScreen(
          sale:
              sale ??
              SaleModel(
                id: '',
                businessId: '',
                sellerUserId: '',
                clientNameSnapshot: '',
                status: '',
                discountAmount: 0,
                totalPriceSnapshot: 0,
                details: [],
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
        );
      },
      Routes.commissionPayments: (context) {
        final businessId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
        return CommissionPaymentScreen(businessId: businessId);
      },
      Routes.cart: (context) {
        final businessId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
        return AppScaffold(
          title: AppTexts.cart,
          appBar: AppBar(
            title: AppText(AppTexts.cart, color: AppColors.kBackgroundColor),
            backgroundColor: AppColors.kPrimaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          mobile: CartScreen(businessId: businessId),
          tablet: CartScreen(businessId: businessId),
          desktop: CartScreen(businessId: businessId),
          marginDesktop: 5,
        );
      },
      Routes.myEarnings: (context) {
        final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final businessId = arguments?['businessId'] as String? ?? '';
        final isAdmin = arguments?['isAdmin'] as bool? ?? false;
        return CommissionPaymentHistoryScreen(businessId: businessId, isAdmin: isAdmin);
      },
    };
  }
}
