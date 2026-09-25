import 'dart:async';

import 'package:admivida/business/features/clients/clients_provider.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class ClientsDebtScreen extends StatelessWidget {
  const ClientsDebtScreen({super.key, required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Directorio de Clientes',
      appBar: AppBar(
        title: AppText('Directorio de Clientes', color: AppColors.kNeutral100),
        iconTheme: const IconThemeData(color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
      ),
      mobile: ClientsDebtListView(businessId: businessId),
      tablet: ClientsDebtListView(businessId: businessId),
      desktop: ClientsDebtListView(businessId: businessId),
      // Si a futuro quieres crear clientes manualmente desde aquí:
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () => NavigationService.navigateTo(context, Routes.createClient, arguments: {'businessId': businessId}),
      //   backgroundColor: AppColors.kPrimaryColor,
      //   icon: const Icon(Icons.person_add),
      //   label: AppText('Nuevo Cliente', color: AppColors.kNeutral100),
      // ),
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

  /// Detecta la proximidad del scroll para disparar la paginación infinita
  void _handleScroll() {
    if (_scrollController.position.extentAfter < 300) {
      ref.read(clientsDebtListProvider(widget.businessId).notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsDebtListProvider(widget.businessId));

    return RefreshIndicator(
      onRefresh: () => ref.read(clientsDebtListProvider(widget.businessId).notifier).refresh(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText('Clientes y Saldos', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
            const Gap(12),
            _buildSearchHeader(),
            Expanded(
              child: clientsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(child: AppText('Error al cargar clientes: $error', color: Colors.red)),
                data: (listState) {
                  final clients = listState.clients; // Asumiendo que tu estado tiene una propiedad 'clients'

                  if (clients.isEmpty) {
                    return Center(child: AppText(AppTexts.noData, color: AppColors.kNeutral600));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: clients.length + (listState.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == clients.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final client = clients[index];
                      final hasDebt = client.debt.total > 0;

                      return AppCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        onTap: () {
                          // Navegamos a la pantalla de abonos pasando el ID del cliente
                          // NavigationService.navigateTo(context, Routes.clientPayments, arguments: {
                          //   'businessId': widget.businessId,
                          //   'clientId': client.id,
                          //   'clientName': client.fullName,
                          // });
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar del cliente
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: hasDebt ? AppColors.kWarning.withValues(alpha: 0.1) : AppColors.kPrimary50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.person_rounded, size: 28, color: hasDebt ? AppColors.kWarning : AppColors.kPrimaryColor),
                            ),
                            const Gap(16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(client.fullName, fontWeight: FontWeight.bold, color: AppColors.kNeutral900, fontSize: 15),
                                  const Gap(4),
                                  if (client.phone != null && client.phone!.isNotEmpty) ...[
                                    AppText(client.phone!, color: AppColors.kNeutral600, fontSize: 12),
                                    const Gap(8),
                                  ],

                                  // Fila de desglose de deuda
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          AppText('Total a cobrar', color: AppColors.kNeutral500, fontSize: 11),
                                          AppText(
                                            '\$${client.debt.total.toStringAsFixed(2)}',
                                            fontWeight: FontWeight.bold,
                                            color: hasDebt ? AppColors.kWarning : AppColors.kSuccess,
                                            fontSize: 16,
                                          ),
                                        ],
                                      ),
                                      if (hasDebt)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            if (client.debt.credit > 0)
                                              AppText('Fiado: \$${client.debt.credit.toStringAsFixed(2)}', color: AppColors.kNeutral600, fontSize: 11),
                                            if (client.debt.layaway > 0)
                                              AppText('Apartado: \$${client.debt.layaway.toStringAsFixed(2)}', color: AppColors.kNeutral600, fontSize: 11),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
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

  // --- HEADER: Buscador ---
  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        onSubmitted: (value) {
          FocusScope.of(context).unfocus();
          ref.read(clientsDebtListProvider(widget.businessId).notifier).setSearchQuery(value);
        },
        decoration: InputDecoration(
          hintText: 'Buscar cliente por nombre...',
          prefixIcon: const Icon(Icons.search, color: AppColors.kNeutral500),
          suffixIcon: _searchController.text.isNotEmpty
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
          fillColor: AppColors.kNeutral50,
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
            borderSide: const BorderSide(color: AppColors.kPrimaryColor),
          ),
        ),
      ),
    );
  }
}
