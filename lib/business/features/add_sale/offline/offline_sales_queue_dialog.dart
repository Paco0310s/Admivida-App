import 'package:admivida/business/features/add_sale/offline/offline_sales_queue_service.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/services/pdf_receipt_service.dart';
import 'package:admivida/common/services/printer_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

/// Banner compacto y reactivo que se muestra en el POS y en el Historial de Ventas
/// cuando no hay conexión a internet o existen ventas pendientes en la cola de Isar.
class OfflineSalesQueueBanner extends ConsumerWidget {
  final String businessId;
  final String businessName;

  const OfflineSalesQueueBanner({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<bool>(
      valueListenable: OfflineSalesQueueService.isOnlineNotifier,
      builder: (context, isOnline, _) {
        return ValueListenableBuilder<List<PendingOfflineSale>>(
          valueListenable: OfflineSalesQueueService.queueNotifier,
          builder: (context, allPending, _) {
            final pendingForBusiness = allPending.where((s) => s.businessId == businessId).toList();
            if (isOnline && pendingForBusiness.isEmpty) {
              return const SizedBox.shrink();
            }

            return ValueListenableBuilder<bool>(
              valueListenable: OfflineSalesQueueService.isSyncingNotifier,
              builder: (context, isSyncing, _) {
                final hasAttention = pendingForBusiness.any((s) => s.requiresAttention);
                final Color bgColor = !isOnline
                    ? const Color(0xFFFEF3C7) // Amber 100
                    : hasAttention
                        ? const Color(0xFFFEE2E2) // Red 100
                        : const Color(0xFFDBEAFE); // Blue 100
                final Color borderColor = !isOnline
                    ? const Color(0xFFF59E0B)
                    : hasAttention
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF3B82F6);
                final Color textColor = !isOnline
                    ? const Color(0xFF92400E)
                    : hasAttention
                        ? const Color(0xFF991B1B)
                        : const Color(0xFF1E40AF);

                String title;
                String subtitle;
                IconData icon;

                if (!isOnline) {
                  icon = Icons.wifi_off_rounded;
                  final cachedCatalogCount = OfflineSalesQueueService.catalogCountByBusinessNotifier.value[businessId];
                  title = pendingForBusiness.isEmpty
                      ? 'Modo sin conexión a internet'
                      : 'Sin internet • ${pendingForBusiness.length} ${pendingForBusiness.length == 1 ? 'venta pendiente' : 'ventas pendientes'} de sincronizar';
                  final catalogHint = (cachedCatalogCount != null && cachedCatalogCount > 0)
                      ? ' Catálogo local listo ($cachedCatalogCount productos).'
                      : '';
                  subtitle = 'Puedes seguir cobrando e imprimiendo tickets.$catalogHint Se sincronizarán automáticamente al volver la conexión.';
                } else if (isSyncing) {
                  icon = Icons.sync_rounded;
                  title = 'Sincronizando ${pendingForBusiness.length} ${pendingForBusiness.length == 1 ? 'venta pendiente' : 'ventas pendientes'} con el servidor...';
                  subtitle = 'Enviando ventas guardadas en orden cronológico.';
                } else if (hasAttention) {
                  icon = Icons.error_outline_rounded;
                  title = '${pendingForBusiness.length} ${pendingForBusiness.length == 1 ? 'venta pendiente requiere' : 'ventas pendientes requieren'} revisión';
                  subtitle = 'Toca para ver el detalle o reintentar la sincronización.';
                } else {
                  icon = Icons.cloud_upload_rounded;
                  title = '${pendingForBusiness.length} ${pendingForBusiness.length == 1 ? 'venta pendiente' : 'ventas pendientes'} de sincronizar';
                  subtitle = 'Conectado a internet. Toca para sincronizar ahora o ver el detalle.';
                }

                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor.withValues(alpha: 0.45)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => OfflineSalesQueueDialog.show(
                        context,
                        businessId: businessId,
                        businessName: businessName,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: borderColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: isSyncing
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: textColor,
                                      ),
                                    )
                                  : Icon(icon, color: textColor, size: 20),
                            ),
                            const Gap(12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    title,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                  const Gap(2),
                                  AppText(
                                    subtitle,
                                    fontSize: 11.5,
                                    color: textColor.withValues(alpha: 0.85),
                                  ),
                                ],
                              ),
                            ),
                            if (pendingForBusiness.isNotEmpty) ...[
                              const Gap(8),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.75),
                                  foregroundColor: textColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: isSyncing
                                    ? null
                                    : () => OfflineSalesQueueDialog.show(
                                          context,
                                          businessId: businessId,
                                          businessName: businessName,
                                        ),
                                icon: const Icon(Icons.list_alt_rounded, size: 16),
                                label: const Text(
                                  'Ver cola',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Modal detallado para consultar, reimprimir o forzar la sincronización de las ventas en la cola de Isar.
class OfflineSalesQueueDialog extends ConsumerWidget {
  final String businessId;
  final String businessName;

  const OfflineSalesQueueDialog({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  static Future<void> show(
    BuildContext context, {
    required String businessId,
    required String businessName,
  }) async {
    await showDialog(
      context: context,
      builder: (_) => OfflineSalesQueueDialog(
        businessId: businessId,
        businessName: businessName,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFmt = DateFormat('dd/MM/yyyy hh:mm a');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ValueListenableBuilder<List<PendingOfflineSale>>(
            valueListenable: OfflineSalesQueueService.queueNotifier,
            builder: (context, allPending, _) {
              final sales = allPending.where((s) => s.businessId == businessId).toList();
              final totalQueuedAmount = sales.fold<double>(
                0.0,
                (sum, item) => sum + item.previewSale.totalPriceSnapshot,
              );

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.kPrimary50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.cloud_sync_rounded, color: AppColors.kPrimaryColor, size: 24),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppText(
                              'Ventas Pendientes de Sincronizar',
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.kNeutral900,
                            ),
                            AppText(
                              sales.isEmpty
                                  ? 'Todas las ventas están sincronizadas con el servidor'
                                  : '${sales.length} ${sales.length == 1 ? 'venta guardada sin internet' : 'ventas guardadas sin internet'} • Total: ${currencyFmt.format(totalQueuedAmount)}',
                              fontSize: 12.5,
                              color: AppColors.kNeutral600,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => NavigationService.pop(context),
                        icon: const Icon(Icons.close_rounded, color: AppColors.kNeutral500),
                      ),
                    ],
                  ),
                  const Gap(14),
                  const Divider(height: 1),
                  const Gap(12),
                  if (sales.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 54, color: AppColors.kSuccess.withValues(alpha: 0.8)),
                          const Gap(12),
                          const AppText(
                            '¡No hay ventas pendientes por sincronizar!',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.kNeutral800,
                          ),
                          const Gap(4),
                          const AppText(
                            'Cualquier venta realizada sin internet aparecerá aquí automáticamente.',
                            fontSize: 12.5,
                            color: AppColors.kNeutral500,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: sales.length,
                        separatorBuilder: (_, _) => const Gap(10),
                        itemBuilder: (context, index) {
                          final item = sales[index];
                          final itemCount = item.dto.details.fold<double>(0, (s, d) => s + d.quantity);

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: item.requiresAttention
                                  ? const Color(0xFFFEF2F2)
                                  : AppColors.kNeutral50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: item.requiresAttention
                                    ? const Color(0xFFFCA5A5)
                                    : AppColors.kNeutral200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: AppText(
                                            item.localId,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.kPrimaryColor,
                                          ),
                                        ),
                                        const Gap(8),
                                        AppText(
                                          dateFmt.format(item.createdAt),
                                          fontSize: 11.5,
                                          color: AppColors.kNeutral600,
                                        ),
                                      ],
                                    ),
                                    AppText(
                                      currencyFmt.format(item.previewSale.totalPriceSnapshot),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.kPrimaryColor,
                                    ),
                                  ],
                                ),
                                const Gap(8),
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline_rounded, size: 15, color: AppColors.kNeutral500),
                                    const Gap(4),
                                    Expanded(
                                      child: AppText(
                                        'Cliente: ${item.dto.clientNameSnapshot} • ${itemCount % 1 == 0 ? itemCount.toInt() : itemCount} art.',
                                        fontSize: 12.5,
                                        color: AppColors.kNeutral700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(4),
                                Text(
                                  item.dto.details
                                      .map((d) => '${d.quantity % 1 == 0 ? d.quantity.toInt() : d.quantity}x ${d.productNameSnapshot}')
                                      .join(', '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.kNeutral500),
                                ),
                                if (item.lastError != null && item.lastError!.isNotEmpty) ...[
                                  const Gap(8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.warning_amber_rounded, size: 15, color: Colors.red),
                                        const Gap(6),
                                        Expanded(
                                          child: AppText(
                                            item.lastError!,
                                            fontSize: 11.5,
                                            color: Colors.red.shade800,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const Gap(8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        foregroundColor: const Color(0xFF0F766E),
                                      ),
                                      onPressed: () => PdfReceiptService.showSalePdfPreviewDialog(
                                        context: context,
                                        sale: item.previewSale,
                                        fallbackBusinessName: businessName,
                                      ),
                                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                                      label: const Text('PDF / WhatsApp', style: TextStyle(fontSize: 12)),
                                    ),
                                    const Gap(8),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        foregroundColor: AppColors.kNeutral700,
                                      ),
                                      onPressed: () async {
                                        final printerService = ref.read(printerServiceProvider);
                                        final savedPrinter = await printerService.getSavedPrinter();
                                        if (savedPrinter == null) {
                                          if (context.mounted) {
                                            SnackbarUtil.showWarning(
                                              context,
                                              'Selecciona una impresora primero desde el botón de impresora en el POS.',
                                            );
                                          }
                                          return;
                                        }
                                        final printObj = item.previewSale.toObjectToPrint(
                                          businessName: businessName,
                                          openDrawer: false,
                                        );
                                        final printed = await printerService.printDocument(savedPrinter, printObj);
                                        if (!context.mounted) return;
                                        if (printed) {
                                          SnackbarUtil.showSuccess(context, 'Ticket enviado a la impresora.');
                                        } else {
                                          SnackbarUtil.showError(context, 'No se pudo conectar con la impresora.');
                                        }
                                      },
                                      icon: const Icon(Icons.print_outlined, size: 16),
                                      label: const Text('Imprimir Ticket', style: TextStyle(fontSize: 12)),
                                    ),
                                    const Gap(8),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        foregroundColor: Colors.red.shade700,
                                      ),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const AppText('¿Descartar venta en cola?', fontWeight: FontWeight.bold),
                                            content: AppText(
                                              'Se eliminará la venta ${item.localId} (${currencyFmt.format(item.previewSale.totalPriceSnapshot)}) de la cola local y no se enviará al servidor.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => NavigationService.pop(ctx, false),
                                                child: const Text('Cancelar'),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                onPressed: () => NavigationService.pop(ctx, true),
                                                child: const Text('Sí, eliminar', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await OfflineSalesQueueService.removePendingSale(item.localId);
                                        }
                                      },
                                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                      label: const Text('Descartar', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const Gap(16),
                  ValueListenableBuilder<bool>(
                    valueListenable: OfflineSalesQueueService.isSyncingNotifier,
                    builder: (context, isSyncing, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => NavigationService.pop(context),
                            child: const AppText('Cerrar', color: AppColors.kNeutral600, fontWeight: FontWeight.w600),
                          ),
                          if (sales.isNotEmpty) ...[
                            const Gap(10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.kPrimaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: isSyncing
                                  ? null
                                  : () async {
                                      final synced = await OfflineSalesQueueService.syncPendingSales(forceRetryAll: true);
                                      if (!context.mounted) return;
                                      if (synced == 0 && !OfflineSalesQueueService.isOnlineNotifier.value) {
                                        SnackbarUtil.showWarning(
                                          context,
                                          'Aún no hay conexión a internet. Se sincronizarán automáticamente al reconectar.',
                                        );
                                      }
                                    },
                              icon: isSyncing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.sync_rounded, size: 18),
                              label: Text(
                                isSyncing ? 'Sincronizando...' : 'Sincronizar ahora',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
