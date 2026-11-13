import 'package:admivida/business/features/add_sale/offline/offline_sales_queue_service.dart';
import 'package:admivida/business/features/cash_shifts/cash_shifts_provider.dart';
import 'package:admivida/business/features/products/products_provider.dart';
import 'package:admivida/business/models/business_model.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/services/secure_storage_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/dashboard_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class BusinessDetailScreen extends ConsumerStatefulWidget {
  const BusinessDetailScreen({super.key, required this.business});

  final BusinessModel business;

  @override
  ConsumerState<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends ConsumerState<BusinessDetailScreen> {
  late BusinessModel business;

  @override
  void initState() {
    super.initState();
    business = widget.business;
    DashboardSession.setActiveBusiness(business);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: business.name,
      appBar: AppBar(
        title: AppText(business.name, color: AppColors.kNeutral100),
        iconTheme: const IconThemeData(color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
      ),
      mobile: _buildView(crossAxisCount: 2),
      tablet: _buildView(crossAxisCount: 3),
      desktop: _buildView(crossAxisCount: 4),
    );
  }

  Widget _buildView({required int crossAxisCount}) {
    final bool isDesktop = crossAxisCount >= 3;
    final List<String> roles = ref.watch(businessRolesProvider(business.id)).value ?? SecureStorageService.getBusinessRoles(business.id);
    final bool isAdmin = roles.any((role) => role == 'ADMIN' || role.contains('ADMIN'));

    final List<Map<String, dynamic>> options = [
      {
        'title': 'Punto de Venta (POS)',
        'subtitle': 'Registra una nueva venta rápida con escáner o catálogo.',
        'icon': Icons.add_shopping_cart_rounded,
        'color': AppColors.kSuccess,
        'isEnabled': true,
        'route': Routes.addSale,
        'role': ['SELLER', 'ADMIN'],
      },
      {
        'title': AppTexts.businessSales,
        'subtitle': AppTexts.businessSalesDescription,
        'icon': Icons.point_of_sale_rounded,
        'color': AppColors.kPrimaryColor,
        'isEnabled': true,
        'route': Routes.sales,
        'role': ['SELLER', 'ADMIN'],
      },
      {
        'title': 'Cortes de Caja',
        'subtitle': 'Abre y cierra turno, registra entradas/retiros y arqueo de efectivo.',
        'icon': Icons.lock_clock_rounded,
        'color': const Color(0xFF0D9488),
        'isEnabled': true,
        'route': Routes.cashShifts,
        'role': ['SELLER', 'ADMIN'],
      },
      {
        'title': AppTexts.businessProducts,
        'subtitle': AppTexts.businessProductsDescription,
        'icon': Icons.inventory_2_rounded,
        'color': AppColors.kSecondaryColor,
        'isEnabled': true,
        'route': Routes.products,
        'role': ['SELLER', 'ADMIN'],
      },
      {
        'title': 'Clientes',
        'subtitle': 'Consulta el directorio de clientes y sus saldos pendientes.',
        'icon': Icons.people_alt_rounded,
        'color': const Color(0xFF0284C7),
        'isEnabled': true,
        'route': Routes.clients,
        'role': ['SELLER', 'ADMIN'],
      },
      {
        'title': 'Reportes y Analíticas',
        'subtitle': 'Ventas, rentabilidad real, valor de inventario y gráficas.',
        'icon': Icons.analytics_rounded,
        'color': const Color(0xFF6366F1),
        'isEnabled': true,
        'route': Routes.businessReports,
        'role': ['ADMIN'],
      },
      {
        'title': 'Movimientos',
        'subtitle': 'Consulta todos los ingresos, egresos y balances de cuentas.',
        'icon': Icons.account_balance_wallet_rounded,
        'color': AppColors.kSuccess,
        'isEnabled': true,
        'route': Routes.transactions,
        'role': ['ADMIN'],
      },
      {
        'title': 'Historial de pagos',
        'subtitle': 'Consulta el historial de pagos recibidos y pendientes.',
        'icon': Icons.savings_rounded,
        'color': const Color(0xFF7C3AED),
        'isEnabled': true,
        'route': Routes.paymentsHistory,
        'role': ['SELLER', 'ADMIN'],
      },
      {
        'title': 'Pago de Comisiones',
        'subtitle': 'Paga las comisiones pendientes a tus vendedores.',
        'icon': Icons.payments_rounded,
        'color': AppColors.kWarning,
        'isEnabled': true,
        'route': Routes.commissionPayments,
        'role': ['ADMIN'],
      },
      {
        'title': 'Pago a Empleados',
        'subtitle': 'Paga a tus empleados un monto libre.',
        'icon': Icons.payment_rounded,
        'color': const Color(0xFFEA580C),
        'isEnabled': true,
        'route': Routes.employeePayments,
        'role': ['ADMIN'],
      },
      {
        'title': 'Colaboradores',
        'subtitle': 'Busca usuarios, asigna roles y configura sus comisiones.',
        'icon': Icons.manage_accounts_rounded,
        'color': const Color(0xFF475569),
        'isEnabled': true,
        'route': Routes.userBusinesses,
        'role': ['ADMIN'],
      },
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF122C38),
                  AppColors.kPrimaryColor,
                  AppColors.kSecondaryColor,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.kPrimaryColor.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -25,
                  top: -35,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(isDesktop ? 26 : 18),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.5),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: business.image == null
                                  ? Container(
                                      width: isDesktop ? 72 : 60,
                                      height: isDesktop ? 72 : 60,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.storefront_rounded, size: 34, color: Colors.white),
                                    )
                                  : SizedBox(
                                      width: isDesktop ? 72 : 60,
                                      height: isDesktop ? 72 : 60,
                                      child: AdaptedFile.network(
                                        business.image!.url,
                                        blurHash: business.image!.blurHash,
                                      ).getWidget(width: isDesktop ? 72 : 60, height: isDesktop ? 72 : 60),
                                    ),
                            ),
                          ),
                          const Gap(16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    AppText(
                                      business.name,
                                      fontSize: isDesktop ? 22 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: AppText(
                                        business.categoryName,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.kPrimary100,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: AppText(
                                        isAdmin ? 'Administrador' : 'Vendedor',
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                if (business.description != null && business.description!.trim().isNotEmpty) ...[
                                  const Gap(5),
                                  AppText(
                                    business.description!,
                                    color: const Color(0xD9FFFFFF),
                                    fontSize: 13,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isDesktop) ...[
                            if (isAdmin) ...[
                              const Gap(12),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final updatedBusiness = await NavigationService.navigateTo(
                                    context,
                                    Routes.createOrUpdateBusinessScreen,
                                    arguments: business,
                                  );

                                  if (updatedBusiness != null && updatedBusiness is BusinessModel) {
                                    setState(() {
                                      business = updatedBusiness;
                                    });
                                    DashboardSession.setActiveBusiness(updatedBusiness);
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                                ),
                                icon: const Icon(Icons.edit_rounded, size: 17, color: Colors.white),
                                label: const AppText(
                                  AppTexts.editBusinessButton,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                            const Gap(10),
                            ElevatedButton.icon(
                              onPressed: () {
                                DashboardSession.navigateToBusinessRoute(
                                  context,
                                  Routes.addSale,
                                  business,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.kPrimaryColor,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                              ),
                              icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                              label: const Text(
                                'Nueva Venta (POS)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ] else if (isAdmin) ...[
                            IconButton(
                              tooltip: AppTexts.editBusinessButton,
                              onPressed: () async {
                                final updatedBusiness = await NavigationService.navigateTo(
                                  context,
                                  Routes.createOrUpdateBusinessScreen,
                                  arguments: business,
                                );

                                if (updatedBusiness != null && updatedBusiness is BusinessModel) {
                                  setState(() {
                                    business = updatedBusiness;
                                  });
                                  DashboardSession.setActiveBusiness(updatedBusiness);
                                }
                              },
                              icon: const Icon(Icons.edit_rounded, color: Colors.white),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap(16),
          _buildLiveStatusBar(context, isAdmin: isAdmin),
          const Gap(20),

          // Grid Options
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.kSecondaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Gap(8),
              const AppText(
                AppTexts.businessOptionsTitle,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.kNeutral900,
              ),
            ],
          ),
          const Gap(14),
          Builder(
            builder: (context) {
              final visibleOptions = options.where((option) {
                final roleRequired = option['role'] as List<String>;
                return roles.any((role) => roleRequired.contains(role));
              }).toList();

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleOptions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isDesktop ? 1.48 : 1.16,
                ),
                itemBuilder: (context, index) {
                  final option = visibleOptions[index];
                  final icon = option['icon'] as IconData;
                  final title = option['title'] as String;
                  final subtitle = option['subtitle'] as String;
                  final color = option['color'] as Color;
                  final isEnabled = option['isEnabled'] as bool;
                  final route = option['route'] as String;
                  final isPosCard = route == Routes.addSale;

                  return AppCard(
                    margin: EdgeInsets.zero,
                    backgroundColor: !isEnabled ? AppColors.kNeutral100 : Colors.white,
                    borderColor: isPosCard ? color.withValues(alpha: 0.45) : AppColors.kNeutral200,
                    padding: const EdgeInsets.all(18),
                    onTap: () {
                      if (isEnabled) {
                        DashboardSession.navigateToBusinessRoute(context, route, business);
                      } else {
                        SnackbarUtil.showInfo(context, 'El módulo $title estará disponible pronto.');
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    color.withValues(alpha: 0.16),
                                    color.withValues(alpha: 0.07),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(icon, color: color, size: 24),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isPosCard) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: AppText(
                                      'Acceso directo',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                  const Gap(6),
                                ],
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.kNeutral100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 15,
                                    color: AppColors.kPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              title,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.kNeutral900,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Gap(4),
                            AppText(
                              subtitle,
                              fontSize: 12,
                              color: AppColors.kNeutral500,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatusBar(BuildContext context, {required bool isAdmin}) {
    final shiftState = ref.watch(cashShiftsProvider(business.id));
    final activeShift = shiftState.activeShift;

    final Color shiftColor;
    final IconData shiftIcon;
    final String shiftText;

    if (shiftState.isLoading && activeShift == null) {
      shiftColor = AppColors.kNeutral500;
      shiftIcon = Icons.sync_rounded;
      shiftText = 'Verificando caja...';
    } else if (activeShift != null) {
      shiftColor = AppColors.kSuccess;
      shiftIcon = Icons.lock_open_rounded;
      shiftText = 'Caja abierta';
    } else if (isAdmin) {
      shiftColor = AppColors.kNeutral600;
      shiftIcon = Icons.lock_outline_rounded;
      shiftText = 'Sin turno (Admin libre)';
    } else {
      shiftColor = AppColors.kWarning;
      shiftIcon = Icons.lock_clock_rounded;
      shiftText = 'Sin turno abierto';
    }

    return ValueListenableBuilder<List<PendingOfflineSale>>(
      valueListenable: OfflineSalesQueueService.queueNotifier,
      builder: (context, allPending, _) {
        final pendingForBiz = allPending.where((s) => s.businessId == business.id).toList();
        final hasAttention = pendingForBiz.any((s) => s.requiresAttention);

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusPill(
              icon: shiftIcon,
              color: shiftColor,
              label: shiftText,
              onTap: () => DashboardSession.navigateToBusinessRoute(
                context,
                Routes.cashShifts,
                business,
              ),
            ),
            if (pendingForBiz.isNotEmpty)
              _StatusPill(
                icon: hasAttention ? Icons.error_outline_rounded : Icons.cloud_upload_outlined,
                color: hasAttention ? AppColors.kError : AppColors.kWarning,
                label: '${pendingForBiz.length} ${pendingForBiz.length == 1 ? 'venta offline' : 'ventas offline'}',
                onTap: () => DashboardSession.navigateToBusinessRoute(
                  context,
                  Routes.addSale,
                  business,
                ),
              ),
            _StatusPill(
              icon: Icons.point_of_sale_rounded,
              color: AppColors.kPrimaryColor,
              label: 'Ir al POS →',
              onTap: () => DashboardSession.navigateToBusinessRoute(
                context,
                Routes.addSale,
                business,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const Gap(6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
