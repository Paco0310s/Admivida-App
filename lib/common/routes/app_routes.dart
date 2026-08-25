import 'package:admivida/business/features/add_business/add_business_screen.dart';
import 'package:admivida/business/features/add_product/add_product_screen.dart';
import 'package:admivida/business/features/add_sale/add_sale_screen.dart';
import 'package:admivida/business/features/add_sale/product_detail/product_detail_screen.dart';
import 'package:admivida/business/features/add_transaction/add_transactions_screen.dart';
import 'package:admivida/business/features/business_detail/business_detail_screen.dart';
import 'package:admivida/business/features/businesses/businesses_screen.dart';
import 'package:admivida/business/features/products/products_screen.dart';
import 'package:admivida/business/features/products/product_detail_screen.dart';
import 'package:admivida/business/features/products/models/product_model.dart';
import 'package:admivida/business/features/sales/sales_screen.dart';
import 'package:admivida/business/features/transactions/transactions_screen.dart';
import 'package:admivida/business/models/business_model.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/features/choose_platform_role/choose_platform_role_screen.dart';
import 'package:flutter/material.dart';
import 'package:admivida/common/features/forgot_password/forgot_password_screen.dart';
import 'package:admivida/common/features/sign_in/sign_in_screen.dart';
import 'package:admivida/common/features/sign_up/sign_up_screen.dart';
import 'package:admivida/common/features/offline/offline_screen.dart';
import 'package:admivida/common/features/splash/splash_screen.dart';
import 'routes.dart';

class AppRoutes {
  Map<String, Widget Function(BuildContext)> get routes {
    return {
      Routes.splash: (context) => const SplashScreen(),
      Routes.signIn: (context) => const SignInScreen(),
      Routes.offline: (context) => const OfflineScreen(),
      Routes.signUp: (context) => const SignUpScreen(),
      Routes.forgotPassword: (context) => const ForgotPasswordScreen(),
      Routes.choosePlatformRole: (context) => const ChoosePlatformRoleScreen(),
      Routes.home: (context) => const BusinessesScreen(),
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
        final product = ModalRoute.of(context)?.settings.arguments as ProductModel?;
        return ProductDetailScreen(
          product:
              product ??
              ProductModel(
                id: '',
                name: AppTexts.noData,
                unitOfMeasure: '',
                isActive: false,
                variants: [],
                images: [],
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                businessId: '',
                productTypeId: '',
              ),
        );
      },
      Routes.addProduct: (context) {
        final businessId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
        return AddProductScreen(businessId: businessId);
      },
      Routes.addBusiness: (context) {
        return AddBusinessScreen();
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
    };
  }
}
