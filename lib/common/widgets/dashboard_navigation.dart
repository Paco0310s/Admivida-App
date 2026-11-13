import 'package:admivida/business/features/add_sale/cart/cart_provider.dart';
import 'package:admivida/business/features/businesses/businesses_provider.dart';
import 'package:admivida/business/features/products/products_provider.dart';
import 'package:admivida/business/features/sales/models/sale_model.dart';
import 'package:admivida/business/models/business_model.dart';
import 'package:admivida/common/constants/app_assets.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/features/sign_in/sign_in_service.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/services/secure_storage_service.dart';
import 'package:admivida/common/widgets/app_image.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

/// Holds global UI state for the desktop/web dashboard shell and active business context.
class DashboardSession {
  DashboardSession._();

  static final ValueNotifier<BusinessModel?> activeBusiness = ValueNotifier<BusinessModel?>(null);
  static final ValueNotifier<bool> isSidebarCollapsed = ValueNotifier<bool>(false);

  /// Updates the active business globally.
  static void setActiveBusiness(BusinessModel? business) {
    if (business != null && business.id.isNotEmpty) {
      activeBusiness.value = business;
    }
  }

  /// Clears session state (e.g. on logout).
  static void clear() {
    activeBusiness.value = null;
  }

  /// Extracts businessId or BusinessModel from the current route's arguments and syncs activeBusiness.
  static String? extractBusinessIdFromRoute(BuildContext context, List<BusinessModel>? knownBusinesses) {
    final settings = ModalRoute.of(context)?.settings;
    final args = settings?.arguments;

    if (args is BusinessModel && args.id.isNotEmpty) {
      if (activeBusiness.value?.id != args.id || activeBusiness.value?.name != args.name) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          activeBusiness.value = args;
        });
      }
      return args.id;
    }

    String? foundBusinessId;
    String? foundBusinessName;

    if (args is String && args.isNotEmpty) {
      foundBusinessId = args;
    } else if (args is Map<String, dynamic>) {
      if (args['businessId'] is String && (args['businessId'] as String).isNotEmpty) {
        foundBusinessId = args['businessId'] as String;
      }
      if (args['businessName'] is String && (args['businessName'] as String).isNotEmpty) {
        foundBusinessName = args['businessName'] as String;
      }
    } else if (args is SaleModel && args.businessId.isNotEmpty) {
      foundBusinessId = args.businessId;
    }

    if (foundBusinessId != null && foundBusinessId.isNotEmpty) {
      if (knownBusinesses != null && knownBusinesses.isNotEmpty) {
        final match = knownBusinesses.where((b) => b.id == foundBusinessId).firstOrNull;
        if (match != null && activeBusiness.value?.id != match.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            activeBusiness.value = match;
          });
        }
      } else if (activeBusiness.value == null && foundBusinessName != null) {
        final fallback = BusinessModel(
          id: foundBusinessId,
          name: foundBusinessName,
          businessCategoryId: '',
          categoryName: '',
          isActive: true,
          createdAt: DateTime.now(),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          activeBusiness.value = fallback;
        });
      }
      return foundBusinessId;
    }

    return activeBusiness.value?.id;
  }

  /// Determines if a route is an authentication or system status route that shouldn't display the dashboard shell.
  static bool isAuthOrPublicRoute(String? routeName) {
    if (routeName == null) return false;
    return routeName == Routes.splash ||
        routeName == Routes.signIn ||
        routeName == Routes.signUp ||
        routeName == Routes.forgotPassword ||
        routeName == Routes.choosePlatformRole ||
        routeName == Routes.offline ||
        routeName == Routes.maintenance ||
        routeName == Routes.updateRequired;
  }

  /// True when the user is currently on a global route (Home, Businesses list, or Personal Finance), not inside a specific business.
  static bool isGlobalRoute(String? routeName) {
    return routeName == Routes.home ||
        routeName == Routes.businesses ||
        routeName == Routes.createOrUpdateBusinessScreen ||
        routeName == Routes.personalDashboard ||
        routeName == Routes.personalAddTransaction ||
        routeName == Routes.personalTransferFunds;
  }

  /// True if the route belongs to the Team & Payments sub-group.
  static bool isTeamOrPaymentsRoute(String? routeName) {
    return routeName == Routes.paymentsHistory ||
        routeName == Routes.commissionPayments ||
        routeName == Routes.employeePayments ||
        routeName == Routes.userBusinesses;
  }

  /// Primary module routes inside a business.
  static bool isBusinessModuleRoute(String? routeName) {
    if (routeName == null) return false;
    return routeName == Routes.sales ||
        routeName == Routes.products ||
        routeName == Routes.clients ||
        routeName == Routes.transactions ||
        routeName == Routes.businessReports ||
        routeName == Routes.paymentsHistory ||
        routeName == Routes.commissionPayments ||
        routeName == Routes.employeePayments ||
        routeName == Routes.userBusinesses ||
        routeName == Routes.cashShifts ||
        routeName == Routes.addSale;
  }

  /// True if the route requires Business Admin permissions.
  static bool isAdminOnlyBusinessRoute(String? routeName) {
    return routeName == Routes.businessReports ||
        routeName == Routes.transactions ||
        routeName == Routes.addTransaction ||
        routeName == Routes.transferFunds ||
        routeName == Routes.userBusinesses ||
        routeName == Routes.commissionPayments ||
        routeName == Routes.employeePayments;
  }

  /// Builds the route arguments expected by [AppRoutes] for a given [targetRoute] and [business].
  static Object buildRouteArguments(String targetRoute, BusinessModel business) {
    if (targetRoute == Routes.businessDetail || targetRoute == Routes.businessReports) {
      return business;
    } else if (targetRoute == Routes.sales || targetRoute == Routes.addSale || targetRoute == Routes.cashShifts) {
      return {'businessId': business.id, 'businessName': business.name};
    } else if (targetRoute == Routes.paymentsHistory) {
      return {
        'businessId': business.id,
        'isAdmin': SecureStorageService.isBusinessAdmin(business.id),
      };
    } else {
      return business.id;
    }
  }

  /// Navigate cleanly to a business route from the Sidebar.
  static void navigateToBusinessRoute(BuildContext context, String targetRoute, BusinessModel business) {
    final previousBusinessId = activeBusiness.value?.id;
    setActiveBusiness(business);
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute == targetRoute && previousBusinessId == business.id) return;

    final Object arguments = buildRouteArguments(targetRoute, business);

    if (targetRoute == Routes.businessDetail) {
      if (isBusinessModuleRoute(currentRoute) || currentRoute == Routes.businessDetail) {
        NavigationService.replaceUntil(
          context,
          Routes.businessDetail,
          arguments: arguments,
          predicate: (route) => isGlobalRoute(route.settings.name) || route.isFirst,
        );
        return;
      }
      NavigationService.navigateTo(context, Routes.businessDetail, arguments: arguments);
      return;
    }

    // If switching from one business module to another, replace so back button returns to BusinessDetail
    if (isBusinessModuleRoute(currentRoute)) {
      NavigationService.replaceWith(context, targetRoute, arguments: arguments);
    } else {
      NavigationService.navigateTo(context, targetRoute, arguments: arguments);
    }
  }

  /// Switches the active business from the Sidebar selector, keeping the user in the equivalent module when appropriate.
  static void switchBusiness(BuildContext context, WidgetRef ref, BusinessModel newBusiness) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final previousBusinessId = activeBusiness.value?.id;

    if (!isGlobalRoute(currentRoute) && previousBusinessId == newBusiness.id) {
      return;
    }

    // Clear POS cart if switching between two different businesses
    if (previousBusinessId != null && previousBusinessId != newBusiness.id) {
      ref.read(cartProvider.notifier).clearCart();
    }

    setActiveBusiness(newBusiness);

    final bool isAdminInNew = SecureStorageService.isBusinessAdmin(newBusiness.id);

    // Determine which route to open for the newly selected business
    String targetRoute = Routes.businessDetail;
    final keepableModuleRoutes = <String>{
      Routes.businessDetail,
      Routes.addSale,
      Routes.sales,
      Routes.cashShifts,
      Routes.products,
      Routes.clients,
      Routes.paymentsHistory,
      Routes.businessReports,
      Routes.transactions,
      Routes.userBusinesses,
      Routes.commissionPayments,
      Routes.employeePayments,
    };

    if (currentRoute == Routes.cart) {
      targetRoute = Routes.addSale;
    } else if (currentRoute != null && keepableModuleRoutes.contains(currentRoute)) {
      if (!isAdminOnlyBusinessRoute(currentRoute) || isAdminInNew) {
        targetRoute = currentRoute;
      }
    }

    final Object arguments = buildRouteArguments(targetRoute, newBusiness);

    if (isGlobalRoute(currentRoute)) {
      NavigationService.navigateTo(context, targetRoute, arguments: arguments);
    } else {
      NavigationService.replaceUntil(
        context,
        targetRoute,
        arguments: arguments,
        predicate: (route) => isGlobalRoute(route.settings.name) || route.isFirst,
      );
    }
  }
}

/// Clean, contextual sidebar navigation widget for Windows / Web / Desktop.
class DashboardSidebar extends ConsumerStatefulWidget {
  final String? currentRoute;

  const DashboardSidebar({
    super.key,
    required this.currentRoute,
  });

  @override
  ConsumerState<DashboardSidebar> createState() => _DashboardSidebarState();
}

class _DashboardSidebarState extends ConsumerState<DashboardSidebar> {
  bool _teamMenuExpanded = false;

  @override
  void initState() {
    super.initState();
    _teamMenuExpanded = DashboardSession.isTeamOrPaymentsRoute(widget.currentRoute);
  }

  @override
  void didUpdateWidget(covariant DashboardSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (DashboardSession.isTeamOrPaymentsRoute(widget.currentRoute)) {
      _teamMenuExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessesAsync = ref.watch(businessesListProvider);
    final knownBusinesses = businessesAsync.value;
    final currentRoute = widget.currentRoute;

    // Sync active business only when inside a business route
    if (!DashboardSession.isGlobalRoute(currentRoute)) {
      DashboardSession.extractBusinessIdFromRoute(context, knownBusinesses);
    }

    final bool showBusinessMenu = !DashboardSession.isGlobalRoute(currentRoute);

    return ValueListenableBuilder<bool>(
      valueListenable: DashboardSession.isSidebarCollapsed,
      builder: (context, isCollapsed, _) {
        final double width = isCollapsed ? 76 : 248;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: width,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF142F3B),
                AppColors.kPrimaryColor,
                Color(0xFF193A47),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 16,
                offset: Offset(2, 0),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBrandHeader(context, isCollapsed),
                const Divider(color: Color(0x1FFFFFFF), height: 1),
                Expanded(
                  child: ValueListenableBuilder<BusinessModel?>(
                    valueListenable: DashboardSession.activeBusiness,
                    builder: (context, activeBiz, _) {
                      final bool isAdmin = activeBiz != null
                          ? (ref.watch(isBusinessAdminProvider(activeBiz.id)).value ??
                              SecureStorageService.isBusinessAdmin(activeBiz.id))
                          : false;

                      return ListView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCollapsed ? 10 : 12,
                          vertical: 14,
                        ),
                        children: [
                          _SidebarItem(
                            icon: Icons.home_rounded,
                            label: AppTexts.home,
                            isSelected: currentRoute == Routes.home,
                            isCollapsed: isCollapsed,
                            onTap: () {
                              if (currentRoute != Routes.home) {
                                NavigationService.navigateTo(context, Routes.home);
                              }
                            },
                          ),
                          const Gap(4),
                          _SidebarItem(
                            icon: Icons.storefront_rounded,
                            label: 'Mis Empresas',
                            isSelected: currentRoute == Routes.businesses || currentRoute == Routes.createOrUpdateBusinessScreen,
                            isCollapsed: isCollapsed,
                            onTap: () {
                              if (currentRoute != Routes.businesses) {
                                NavigationService.navigateTo(context, Routes.businesses);
                              }
                            },
                          ),
                          const Gap(4),
                          _SidebarItem(
                            icon: Icons.account_balance_wallet_rounded,
                            label: 'Control Personal',
                            isSelected: currentRoute == Routes.personalDashboard ||
                                currentRoute == Routes.personalAddTransaction ||
                                currentRoute == Routes.personalTransferFunds,
                            isCollapsed: isCollapsed,
                            onTap: () {
                              if (currentRoute != Routes.personalDashboard) {
                                NavigationService.navigateTo(context, Routes.personalDashboard);
                              }
                            },
                          ),

                          // Business Switcher (always accessible when the user has businesses or an active business)
                          if ((knownBusinesses != null && knownBusinesses.isNotEmpty) || activeBiz != null) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: Color(0x24FFFFFF), height: 1),
                            ),
                            _BusinessSwitcherCard(
                              activeBusiness: activeBiz,
                              businesses: knownBusinesses ?? (activeBiz != null ? [activeBiz] : const []),
                              isCollapsed: isCollapsed,
                              isInsideBusiness: showBusinessMenu && activeBiz != null,
                              onBusinessSelected: (selected) {
                                DashboardSession.switchBusiness(context, ref, selected);
                              },
                              onViewAllBusinesses: () {
                                if (currentRoute != Routes.businesses) {
                                  NavigationService.navigateTo(context, Routes.businesses);
                                }
                              },
                            ),
                            const Gap(8),
                            Builder(
                              builder: (context) {
                                final posBiz = activeBiz ??
                                    (knownBusinesses != null && knownBusinesses.isNotEmpty ? knownBusinesses.first : null);
                                if (posBiz == null) return const SizedBox.shrink();
                                return _SidebarItem(
                                  icon: Icons.add_shopping_cart_rounded,
                                  label: 'Punto de Venta (POS)',
                                  isSelected: currentRoute == Routes.addSale || currentRoute == Routes.cart,
                                  isHighlighted: true,
                                  isCollapsed: isCollapsed,
                                  onTap: () {
                                    if (currentRoute == Routes.addSale && activeBiz?.id == posBiz.id) return;
                                    if (activeBiz?.id != posBiz.id) {
                                      ref.read(cartProvider.notifier).clearCart();
                                      DashboardSession.setActiveBusiness(posBiz);
                                    }
                                    DashboardSession.navigateToBusinessRoute(context, Routes.addSale, posBiz);
                                  },
                                );
                              },
                            ),
                            if (showBusinessMenu && activeBiz != null) const Gap(6),
                          ],

                          // Contextual Business Menu: ONLY shown when inside a business
                          if (showBusinessMenu && activeBiz != null) ...[
                            _SidebarItem(
                              icon: Icons.dashboard_rounded,
                              label: 'Resumen',
                              isSelected: currentRoute == Routes.businessDetail,
                              isCollapsed: isCollapsed,
                              onTap: () => DashboardSession.navigateToBusinessRoute(context, Routes.businessDetail, activeBiz),
                            ),
                            const Gap(4),
                            _SidebarItem(
                              icon: Icons.point_of_sale_rounded,
                              label: AppTexts.businessSales,
                              isSelected: currentRoute == Routes.sales || currentRoute == Routes.saleDetail,
                              isCollapsed: isCollapsed,
                              onTap: () => DashboardSession.navigateToBusinessRoute(context, Routes.sales, activeBiz),
                            ),
                            const Gap(4),
                            _SidebarItem(
                              icon: Icons.lock_clock_rounded,
                              label: 'Cortes de Caja',
                              isSelected: currentRoute == Routes.cashShifts,
                              isCollapsed: isCollapsed,
                              onTap: () => DashboardSession.navigateToBusinessRoute(context, Routes.cashShifts, activeBiz),
                            ),
                            const Gap(4),
                            _SidebarItem(
                              icon: Icons.inventory_2_rounded,
                              label: AppTexts.businessProducts,
                              isSelected: currentRoute == Routes.products ||
                                  currentRoute == Routes.productDetail ||
                                  currentRoute == Routes.createOrUpdateProduct,
                              isCollapsed: isCollapsed,
                              onTap: () => DashboardSession.navigateToBusinessRoute(context, Routes.products, activeBiz),
                            ),
                            const Gap(4),
                            _SidebarItem(
                              icon: Icons.people_alt_rounded,
                              label: 'Clientes',
                              isSelected: currentRoute == Routes.clients ||
                                  currentRoute == Routes.clientPayments ||
                                  currentRoute == Routes.createClient,
                              isCollapsed: isCollapsed,
                              onTap: () => DashboardSession.navigateToBusinessRoute(context, Routes.clients, activeBiz),
                            ),
                            const Gap(4),
                            if (isAdmin) ...[
                              _SidebarItem(
                                icon: Icons.analytics_rounded,
                                label: 'Reportes y Métricas',
                                isSelected: currentRoute == Routes.businessReports,
                                isCollapsed: isCollapsed,
                                onTap: () => DashboardSession.navigateToBusinessRoute(context, Routes.businessReports, activeBiz),
                              ),
                              const Gap(4),
                              _SidebarItem(
                                icon: Icons.account_balance_wallet_rounded,
                                label: 'Movimientos',
                                isSelected: currentRoute == Routes.transactions ||
                                    currentRoute == Routes.addTransaction ||
                                    currentRoute == Routes.transferFunds,
                                isCollapsed: isCollapsed,
                                onTap: () => DashboardSession.navigateToBusinessRoute(context, Routes.transactions, activeBiz),
                              ),
                              const Gap(4),

                              // Grouped Secondary Admin Options ("Equipo y Pagos")
                              _SidebarItem(
                                icon: Icons.groups_rounded,
                                label: 'Equipo y Pagos',
                                isSelected: DashboardSession.isTeamOrPaymentsRoute(currentRoute) && (isCollapsed || !_teamMenuExpanded),
                                isCollapsed: isCollapsed,
                                trailingIcon: isCollapsed
                                    ? null
                                    : (_teamMenuExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded),
                                onTap: () {
                                  if (isCollapsed) {
                                    DashboardSession.navigateToBusinessRoute(context, Routes.userBusinesses, activeBiz);
                                  } else {
                                    setState(() => _teamMenuExpanded = !_teamMenuExpanded);
                                  }
                                },
                              ),
                              if (_teamMenuExpanded && !isCollapsed)
                                Padding(
                                  padding: const EdgeInsets.only(left: 14, top: 4),
                                  child: Column(
                                    children: [
                                      _SidebarItem(
                                        icon: Icons.manage_accounts_rounded,
                                        label: 'Colaboradores',
                                        isSelected: currentRoute == Routes.userBusinesses,
                                        isCollapsed: false,
                                        isCompact: true,
                                        onTap: () => DashboardSession.navigateToBusinessRoute(context, Routes.userBusinesses, activeBiz),
                                      ),
                                      const Gap(2),
                                      _SidebarItem(
                                        icon: Icons.payments_rounded,
                                        label: 'Pago de Comisiones',
                                        isSelected: currentRoute == Routes.commissionPayments,
                                        isCollapsed: false,
                                        isCompact: true,
                                        onTap: () => DashboardSession.navigateToBusinessRoute(context, Routes.commissionPayments, activeBiz),
                                      ),
                                      const Gap(2),
                                      _SidebarItem(
                                        icon: Icons.payment_rounded,
                                        label: 'Pago a Empleados',
                                        isSelected: currentRoute == Routes.employeePayments,
                                        isCollapsed: false,
                                        isCompact: true,
                                        onTap: () => DashboardSession.navigateToBusinessRoute(context, Routes.employeePayments, activeBiz),
                                      ),
                                      const Gap(2),
                                      _SidebarItem(
                                        icon: Icons.savings_rounded,
                                        label: 'Historial de Pagos',
                                        isSelected: currentRoute == Routes.paymentsHistory,
                                        isCollapsed: false,
                                        isCompact: true,
                                        onTap: () => DashboardSession.navigateToBusinessRoute(context, Routes.paymentsHistory, activeBiz),
                                      ),
                                    ],
                                  ),
                                ),
                            ] else ...[
                              _SidebarItem(
                                icon: Icons.savings_rounded,
                                label: 'Historial de Pagos',
                                isSelected: currentRoute == Routes.paymentsHistory,
                                isCollapsed: isCollapsed,
                                onTap: () => DashboardSession.navigateToBusinessRoute(context, Routes.paymentsHistory, activeBiz),
                              ),
                            ],
                          ],
                        ],
                      );
                    },
                  ),
                ),
                const Divider(color: Color(0x1FFFFFFF), height: 1),
                Padding(
                  padding: EdgeInsets.all(isCollapsed ? 10 : 12),
                  child: _SidebarItem(
                    icon: Icons.logout_rounded,
                    label: AppTexts.logout,
                    isSelected: false,
                    isCollapsed: isCollapsed,
                    iconColor: const Color(0xFFFF8A80),
                    onTap: () async {
                      await SignInService.signOut();
                      if (!context.mounted) return;
                      NavigationService.replaceUntil(context, Routes.signIn);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBrandHeader(BuildContext context, bool isCollapsed) {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 10 : 16),
      child: Row(
        mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
        children: [
          if (!isCollapsed)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  if (widget.currentRoute != Routes.home) {
                    NavigationService.navigateTo(context, Routes.home);
                  }
                },
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: AppImage(
                        AdaptedFile.asset(AppAssets.icon),
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const Gap(10),
                    const Expanded(
                      child: AppText(
                        AppTexts.appName,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          IconButton(
            tooltip: isCollapsed ? 'Expandir menú' : 'Contraer menú',
            onPressed: () {
              DashboardSession.isSidebarCollapsed.value = !isCollapsed;
            },
            icon: Icon(
              isCollapsed ? Icons.menu_rounded : Icons.menu_open_rounded,
              color: Colors.white70,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessSwitcherCard extends StatefulWidget {
  final BusinessModel? activeBusiness;
  final List<BusinessModel> businesses;
  final bool isCollapsed;
  final bool isInsideBusiness;
  final ValueChanged<BusinessModel> onBusinessSelected;
  final VoidCallback onViewAllBusinesses;

  const _BusinessSwitcherCard({
    required this.activeBusiness,
    required this.businesses,
    required this.isCollapsed,
    required this.isInsideBusiness,
    required this.onBusinessSelected,
    required this.onViewAllBusinesses,
  });

  @override
  State<_BusinessSwitcherCard> createState() => _BusinessSwitcherCardState();
}

class _BusinessSwitcherCardState extends State<_BusinessSwitcherCard> {
  bool _isHovered = false;

  String _initialsFor(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'N';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  Widget _buildBusinessAvatar(BusinessModel? biz, {double size = 32}) {
    final imageUrl = biz?.image?.url;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: size,
          height: size,
          child: AdaptedFile.network(imageUrl, blurHash: biz?.image?.blurHash).getWidget(
            fit: BoxFit.cover,
            width: size,
            height: size,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.kSecondaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        biz != null ? _initialsFor(biz.name) : 'N',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showSwitcherMenu(BuildContext context) async {
    if (widget.businesses.isEmpty) {
      widget.onViewAllBusinesses();
      return;
    }

    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final Offset topLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
    final Offset bottomRight = button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay);

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        Offset(topLeft.dx, bottomRight.dy + 4),
        Offset(bottomRight.dx, bottomRight.dy + 4),
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<String>(
      context: context,
      position: position,
      elevation: 10,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.kNeutral200),
      ),
      constraints: const BoxConstraints(minWidth: 250, maxWidth: 290),
      items: <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          enabled: false,
          height: 32,
          child: Text(
            'CAMBIAR DE NEGOCIO',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.kNeutral500,
            ),
          ),
        ),
        ...widget.businesses.map((biz) {
          final isCurrent = widget.activeBusiness?.id == biz.id && widget.isInsideBusiness;
          return PopupMenuItem<String>(
            value: biz.id,
            height: 52,
            child: Row(
              children: [
                _buildBusinessAvatar(biz, size: 32),
                const Gap(10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        biz.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                          color: isCurrent ? AppColors.kPrimaryColor : AppColors.kNeutral900,
                        ),
                      ),
                      if (biz.categoryName.isNotEmpty)
                        Text(
                          biz.categoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.kNeutral500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isCurrent)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.kSecondaryColor,
                    size: 18,
                  )
                else
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.kNeutral300,
                    size: 13,
                  ),
              ],
            ),
          );
        }),
        const PopupMenuDivider(height: 8),
        const PopupMenuItem<String>(
          value: '__view_all__',
          height: 40,
          child: Row(
            children: [
              Icon(Icons.storefront_rounded, size: 18, color: AppColors.kPrimaryColor),
              Gap(10),
              Text(
                'Ver todas mis empresas',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (selected == null) return;
    if (selected == '__view_all__') {
      widget.onViewAllBusinesses();
      return;
    }

    final targetBiz = widget.businesses.where((b) => b.id == selected).firstOrNull;
    if (targetBiz != null) {
      widget.onBusinessSelected(targetBiz);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayBiz = widget.activeBusiness ?? (widget.businesses.isNotEmpty ? widget.businesses.first : null);
    final bgColor = _isHovered
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.08);

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.symmetric(
        horizontal: widget.isCollapsed ? 0 : 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: _isHovered ? 0.24 : 0.14),
        ),
      ),
      child: widget.isCollapsed
          ? Center(child: _buildBusinessAvatar(displayBiz, size: 32))
          : Row(
              children: [
                _buildBusinessAvatar(displayBiz, size: 32),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        widget.isInsideBusiness ? 'NEGOCIO ACTIVO' : 'CAMBIAR A NEGOCIO',
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.kPrimary200,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(1),
                      AppText(
                        displayBiz?.name ?? 'Seleccionar negocio',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.unfold_more_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
              ],
            ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showSwitcherMenu(context),
        child: Tooltip(
          message: displayBiz != null ? 'Cambiar de negocio (${displayBiz.name})' : 'Seleccionar negocio',
          child: content,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final bool isCompact;
  final bool isHighlighted;
  final IconData? trailingIcon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
    this.isCompact = false,
    this.isHighlighted = false,
    this.trailingIcon,
    this.iconColor,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? AppColors.kSecondaryColor
        : widget.isHighlighted
            ? (_isHovered ? AppColors.kSecondaryColor.withValues(alpha: 0.36) : AppColors.kSecondaryColor.withValues(alpha: 0.22))
            : (_isHovered ? Colors.white.withValues(alpha: 0.08) : Colors.transparent);

    final fgColor = widget.iconColor ??
        (widget.isSelected || widget.isHighlighted ? Colors.white : Colors.white.withValues(alpha: 0.82));

    final itemContent = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(
        horizontal: widget.isCollapsed ? 0 : 12,
        vertical: widget.isCompact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(11),
        border: widget.isHighlighted && !widget.isSelected
            ? Border.all(color: AppColors.kPrimary200.withValues(alpha: 0.45), width: 1)
            : (widget.isSelected
                ? Border.all(color: Colors.white.withValues(alpha: 0.16), width: 1)
                : null),
        boxShadow: widget.isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: widget.isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(widget.icon, color: fgColor, size: widget.isCompact ? 18 : 20),
          if (!widget.isCollapsed) ...[
            const Gap(12),
            Expanded(
              child: AppText(
                widget.label,
                fontSize: widget.isCompact ? 12.5 : 13.5,
                fontWeight: widget.isSelected || widget.isHighlighted ? FontWeight.w700 : FontWeight.w500,
                color: fgColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.isHighlighted && widget.trailingIcon == null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'RÁPIDO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            if (widget.trailingIcon != null)
              Icon(widget.trailingIcon, color: Colors.white60, size: 18),
          ],
        ],
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: widget.isCollapsed
            ? Tooltip(
                message: widget.label,
                child: itemContent,
              )
            : itemContent,
      ),
    );
  }
}

/// Minimalist top header bar for Desktop/Web Dashboard mode.
class DashboardTopBar extends StatelessWidget {
  final String title;
  final String? currentRoute;
  final AppBar? originalAppBar;

  const DashboardTopBar({
    super.key,
    required this.title,
    required this.currentRoute,
    this.originalAppBar,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = NavigationService.canPop(context);
    final isRootDashboardRoute = currentRoute == Routes.home || currentRoute == Routes.businesses;

    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: AppColors.kNeutral200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (originalAppBar?.leading != null) ...[
            IconTheme(
              data: const IconThemeData(color: AppColors.kPrimaryColor),
              child: originalAppBar!.leading!,
            ),
            const Gap(8),
          ] else if (canPop && !isRootDashboardRoute) ...[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.kNeutral100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.kNeutral200),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => NavigationService.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.kPrimaryColor),
                tooltip: 'Regresar',
              ),
            ),
            const Gap(12),
          ],
          Expanded(
            child: ValueListenableBuilder<BusinessModel?>(
              valueListenable: DashboardSession.activeBusiness,
              builder: (context, activeBiz, _) {
                final showBizBreadcrumb = activeBiz != null &&
                    !DashboardSession.isGlobalRoute(currentRoute) &&
                    currentRoute != Routes.businessDetail;

                return Row(
                  children: [
                    if (showBizBreadcrumb) ...[
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => DashboardSession.navigateToBusinessRoute(
                          context,
                          Routes.businessDetail,
                          activeBiz,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.kNeutral100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.kNeutral200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.storefront_rounded, size: 14, color: AppColors.kPrimaryColor),
                              const Gap(6),
                              AppText(
                                activeBiz.name,
                                fontSize: 12.5,
                                color: AppColors.kNeutral700,
                                fontWeight: FontWeight.w600,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.kNeutral400),
                      ),
                    ],
                    Flexible(
                      child: AppText(
                        title,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.kNeutral900,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          ValueListenableBuilder<BusinessModel?>(
            valueListenable: DashboardSession.activeBusiness,
            builder: (context, activeBiz, _) {
              final showQuickPos = activeBiz != null &&
                  !DashboardSession.isGlobalRoute(currentRoute) &&
                  currentRoute != Routes.addSale &&
                  currentRoute != Routes.cart &&
                  currentRoute != Routes.businessDetail;
              if (!showQuickPos) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: OutlinedButton.icon(
                  onPressed: () => DashboardSession.navigateToBusinessRoute(
                    context,
                    Routes.addSale,
                    activeBiz,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.kSecondaryColor,
                    backgroundColor: AppColors.kPrimary50.withValues(alpha: 0.45),
                    side: BorderSide(color: AppColors.kSecondaryColor.withValues(alpha: 0.35)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                  label: const Text(
                    'Abrir POS',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
              );
            },
          ),
          if (originalAppBar?.actions != null)
            IconTheme(
              data: const IconThemeData(color: AppColors.kPrimaryColor),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: originalAppBar!.actions!,
              ),
            ),
        ],
      ),
    );
  }
}
