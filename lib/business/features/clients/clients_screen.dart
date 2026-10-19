import 'dart:async';

import 'package:admivida/business/features/clients/clients_provider.dart';
import 'package:admivida/business/features/clients/models/client_debt_model.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class ClientsDebtScreen extends StatelessWidget {
  const ClientsDebtScreen({super.key, required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return AppScaffold(
      title: 'Directorio de Clientes',
      appBar: AppBar(
        title: const AppText('Directorio de Clientes', color: AppColors.kNeutral100),
        iconTheme: const IconThemeData(color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
      ),
      mobile: ClientsDebtListView(businessId: businessId),
      tablet: ClientsDebtListView(businessId: businessId),
      desktop: ClientsDebtListView(businessId: businessId),
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              onPressed: () => NavigationService.navigateTo(context, Routes.createClient, arguments: {'businessId': businessId}),
              backgroundColor: AppColors.kPrimaryColor,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const AppText('Nuevo Cliente', color: AppColors.kNeutral100, fontWeight: FontWeight.w600),
            )
          : null,
    );
  }
}

class ClientsDebtListView extends ConsumerStatefulWidget {
  const ClientsDebtListView({super.key, required this.businessId});

  final String businessId;

  @override
  ConsumerState<ClientsDebtListView> createState() => _ClientsDebtListViewState();
}

class _ClientsDebtListViewState extends ConsumerState<ClientsDebtListView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(clientsDebtListProvider(widget.businessId).notifier).setSearchQuery(query);
    });
  }

  void _handleScroll() {
    if (_scrollController.position.extentAfter < 300) {
      ref.read(clientsDebtListProvider(widget.businessId).notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsDebtListProvider(widget.businessId));
    final bool isMobile = Responsive.isMobile(context);
    final bool isWideDesktop = MediaQuery.of(context).size.width >= 1280;

    return RefreshIndicator(
      onRefresh: () => ref.read(clientsDebtListProvider(widget.businessId).notifier).refresh(),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchHeader(isMobile: isMobile),
            const Gap(8),
            Expanded(
              child: clientsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(child: AppText('Error al cargar clientes: $error', color: Colors.red)),
                data: (listState) {
                  final clients = listState.clients;

                  if (clients.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(color: AppColors.kPrimary50, shape: BoxShape.circle),
                            child: const Icon(Icons.people_alt_rounded, size: 36, color: AppColors.kPrimaryColor),
                          ),
                          const Gap(12),
                          const AppText(AppTexts.noData, color: AppColors.kNeutral600, fontWeight: FontWeight.w600),
                        ],
                      ),
                    );
                  }

                  if (isWideDesktop) {
                    return GridView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 126,
                      ),
                      itemCount: clients.length + (listState.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == clients.length) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        return _buildClientCard(context, clients[index], isGrid: true);
                      },
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: clients.length + (listState.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == clients.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _buildClientCard(context, clients[index], isGrid: false);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, ClientWithDebtModel client, {required bool isGrid}) {
    final hasDebt = client.debt.total > 0;

    return AppCard(
      margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: () {
        NavigationService.navigateTo(
          context,
          Routes.clientPayments,
          arguments: {'businessId': widget.businessId, 'clientId': client.id, 'clientName': client.fullName},
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: hasDebt ? AppColors.kWarning.withValues(alpha: 0.12) : AppColors.kPrimary50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.person_rounded, size: 28, color: hasDebt ? AppColors.kWarning : AppColors.kPrimaryColor),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(client.fullName, fontWeight: FontWeight.bold, color: AppColors.kNeutral900, fontSize: 15, maxLines: 1, overflow: TextOverflow.ellipsis),
                const Gap(3),
                if (client.phone != null && client.phone!.isNotEmpty)
                  AppText(client.phone!, color: AppColors.kNeutral600, fontSize: 12)
                else
                  const AppText('Sin teléfono registrado', color: AppColors.kNeutral400, fontSize: 11.5),
                if (hasDebt) ...[
                  const Gap(6),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (client.debt.credit > 0) AppText('Fiado: \$${client.debt.credit.toStringAsFixed(2)}', color: AppColors.kNeutral600, fontSize: 11),
                      if (client.debt.layaway > 0) AppText('Apartado: \$${client.debt.layaway.toStringAsFixed(2)}', color: AppColors.kNeutral600, fontSize: 11),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Gap(12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const AppText('Total a cobrar', color: AppColors.kNeutral500, fontSize: 10.5),
              const Gap(2),
              AppText(
                '\$${client.debt.total.toStringAsFixed(2)}',
                fontWeight: FontWeight.bold,
                color: hasDebt ? AppColors.kWarning : AppColors.kSuccess,
                fontSize: 16.5,
              ),
              const Gap(4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: hasDebt ? AppColors.kWarning.withValues(alpha: 0.12) : AppColors.kSuccess.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppText(
                  hasDebt ? 'Con saldo' : 'Al corriente',
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: hasDebt ? AppColors.kWarning : AppColors.kSuccess,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader({required bool isMobile}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, child) {
                return TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    FocusScope.of(context).unfocus();
                    ref.read(clientsDebtListProvider(widget.businessId).notifier).setSearchQuery(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar cliente por nombre o teléfono...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.kNeutral500),
                    suffixIcon: value.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              FocusScope.of(context).unfocus();
                              ref.read(clientsDebtListProvider(widget.businessId).notifier).setSearchQuery('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.kNeutral200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.kNeutral200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.kPrimaryColor, width: 1.5),
                    ),
                  ),
                );
              },
            ),
          ),
          if (!isMobile) ...[
            const Gap(10),
            ElevatedButton.icon(
              onPressed: () => NavigationService.navigateTo(
                context,
                Routes.createClient,
                arguments: {'businessId': widget.businessId},
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kPrimaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text(
                'Nuevo Cliente',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
