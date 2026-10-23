import 'package:admivida/business/features/businesses/businesses_provider.dart';
import 'package:admivida/business/features/products/products_provider.dart';
import 'package:admivida/business/features/sales/models/sale_model.dart';
import 'package:admivida/business/models/business_model.dart';
import 'package:admivida/common/constants/app_assets.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/isar_cache_service.dart';
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

  /// True when the user is currently on a global route (Home or Businesses list), not inside a specific business.
  static bool isGlobalRoute(String? routeName) {
    return routeName == Routes.home ||
        routeName == Routes.businesses ||
        routeName == Routes.createOrUpdateBusinessScreen;
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
        routeName == Routes.paymentsHistory ||
        routeName == Routes.commissionPayments ||
        routeName == Routes.employeePayments ||
        routeName == Routes.userBusinesses ||
        routeName == Routes.addSale;
  }

  /// Navigate cleanly to a business route from the Sidebar.
  static void navigateToBusinessRoute(BuildContext context, String targetRoute, BusinessModel business) {
    setActiveBusiness(business);
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute == targetRoute) return;

    Object? arguments;
    if (targetRoute == Routes.businessDetail) {
      arguments = business;
    } else if (targetRoute == Routes.sales || targetRoute == Routes.addSale) {
      arguments = {'businessId': business.id, 'businessName': business.name};
    } else if (targetRoute == Routes.paymentsHistory) {
      arguments = {
        'businessId': business.id,
        'isAdmin': SecureStorageService.isBusinessAdmin(business.id),
      };
    } else {
      arguments = business.id;
    }

    if (targetRoute == Routes.businessDetail) {
      if (isBusinessModuleRoute(currentRoute) && NavigationService.canPop(context)) {
        NavigationService.popUntil(context, (route) => route.settings.name == Routes.businessDetail || route.isFirst);
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
            color: AppColors.kPrimaryColor,
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
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

                          // Contextual Business Menu: ONLY shown when inside a business
                          if (showBusinessMenu && activeBiz != null) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: Color(0x24FFFFFF), height: 1),
                            ),
                            if (!isCollapsed)
                              Padding(
                                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                                child: AppText(
                                  activeBiz.name.toUpperCase(),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.kPrimary200,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
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
                              isSelected: currentRoute == Routes.sales ||
                                  currentRoute == Routes.saleDetail ||
                                  currentRoute == Routes.addSale ||
                                  currentRoute == Routes.cart,
                              isCollapsed: isCollapsed,
                              onTap: () => DashboardSession.navigateToBusinessRoute(context, Routes.sales, activeBiz),
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
                      DashboardSession.clear();
                      await SecureStorageService.clear();
                      await IsarCacheService.clearCache();
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

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final bool isCompact;
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
        : _isHovered
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.transparent;

    final fgColor = widget.iconColor ?? (widget.isSelected ? Colors.white : Colors.white.withValues(alpha: 0.82));

    final itemContent = Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isCollapsed ? 0 : 12,
        vertical: widget.isCompact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
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
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                color: fgColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.kNeutral200, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (originalAppBar?.leading != null) ...[
            IconTheme(
              data: const IconThemeData(color: AppColors.kNeutral800),
              child: originalAppBar!.leading!,
            ),
            const Gap(8),
          ] else if (canPop && !isRootDashboardRoute) ...[
            IconButton(
              onPressed: () => NavigationService.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.kNeutral800),
              tooltip: 'Regresar',
            ),
            const Gap(8),
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
                        onTap: () => DashboardSession.navigateToBusinessRoute(
                          context,
                          Routes.businessDetail,
                          activeBiz,
                        ),
                        child: AppText(
                          activeBiz.name,
                          fontSize: 15,
                          color: AppColors.kNeutral500,
                          fontWeight: FontWeight.w500,
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
          if (originalAppBar?.actions != null)
            IconTheme(
              data: const IconThemeData(color: AppColors.kNeutral800),
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
