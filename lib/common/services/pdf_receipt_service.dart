import 'dart:io';
import 'dart:typed_data';

import 'package:admivida/business/features/cash_shifts/models/cash_shift_model.dart';
import 'package:admivida/business/features/clients/models/client_payment_response.dart';
import 'package:admivida/business/features/sales/models/sale_model.dart';
import 'package:admivida/business/models/business_model.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/logging/app_logger.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/dashboard_navigation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Generates Letter-sized (8.5x11") PDF receipts styled after clean ERP documents
/// (Dolibarr layout) for WhatsApp forwarding and standard desktop/office printers.
/// Supports sales (online & offline), client debt payments (abonos), and X/Z cash shifts.
class PdfReceiptService {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  static final _brandTeal = PdfColor.fromHex('#0E7490');
  static final _headerBg = PdfColor.fromHex('#F3F4F6');
  static final _emitterBg = PdfColor.fromHex('#EDEDED');
  static final _borderColor = PdfColor.fromHex('#6B7280');
  static final _subtleBorder = PdfColor.fromHex('#D1D5DB');
  static final _textDark = PdfColor.fromHex('#111827');
  static final _textMuted = PdfColor.fromHex('#4B5563');

  static String _money(double value) => _currencyFormat.format(value);

  static String _formatQty(double qty) {
    if (qty % 1 == 0) return qty.toInt().toString();
    return qty.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  /// Replaces characters outside WinAnsi (e.g. emojis/special bullets) so default PDF fonts never throw or draw boxes.
  static String _safeText(String input) {
    return input
        .replaceAll('\u2022', '-')
        .replaceAll('•', '-')
        .replaceAll(RegExp(r'[^\x20-\x7E\xA0-\xFF\n]'), '');
  }

  static String _shortFolio(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return 'N/D';
    if (trimmed.startsWith('OFFLINE-') || trimmed.length <= 10) return trimmed;
    return trimmed.substring(trimmed.length - 8).toUpperCase();
  }

  static String _saleDocumentTitle(String status) {
    switch (status.toUpperCase()) {
      case 'CREDIT':
        return 'NOTA DE VENTA (CREDITO)';
      case 'LAYAWAY':
        return 'NOTA DE APARTADO';
      case 'PENDING':
        return 'COMPROBANTE PENDIENTE';
      case 'CANCELLED':
        return 'NOTA CANCELADA';
      case 'REFUNDED':
        return 'NOTA DEVUELTA';
      default:
        return 'NOTA DE VENTA';
    }
  }

  static String _saleStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return 'Pagada';
      case 'CREDIT':
        return 'A Credito (Fiado)';
      case 'LAYAWAY':
        return 'Apartado';
      case 'PENDING':
        return 'Pendiente';
      case 'CANCELLED':
        return 'Cancelada';
      case 'REFUNDED':
        return 'Devuelta';
      default:
        return status;
    }
  }

  static Future<pw.ImageProvider?> _tryLoadLogo(String? url) async {
    if (url == null || url.trim().isEmpty) return null;
    final cleanUrl = url.trim();
    if (cleanUrl.toLowerCase().contains('.svg')) return null;

    try {
      final response = await http.get(Uri.parse(cleanUrl)).timeout(const Duration(seconds: 2));
      if (response.statusCode >= 200 && response.statusCode < 300 && response.bodyBytes.isNotEmpty) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (_) {
      // Offline or slow connection: fallback silently to text-only header
    }
    return null;
  }

  static List<String> _extractMetadataLines(BusinessModel? business) {
    final meta = business?.metadata;
    if (meta == null || meta.isEmpty) return const [];

    String? pickFirst(List<String> keys) {
      for (final key in keys) {
        final raw = meta[key];
        if (raw != null && raw.toString().trim().isNotEmpty) {
          return raw.toString().trim();
        }
      }
      return null;
    }

    final lines = <String>[];
    final address = pickFirst(['address', 'direccion', 'domicilio']);
    final phone = pickFirst(['phone', 'telefono', 'whatsapp', 'tel']);
    final email = pickFirst(['email', 'correo']);
    final rfc = pickFirst(['rfc', 'taxId', 'nif']);

    if (address != null) lines.add(_safeText(address));
    if (phone != null) lines.add(_safeText('Tel: $phone'));
    if (email != null) lines.add(_safeText('Email: $email'));
    if (rfc != null) lines.add(_safeText('RFC: $rfc'));
    return lines;
  }

  static Future<({BusinessModel? business, String name, pw.ImageProvider? logo, List<String> meta})>
      _resolveBusinessContext({
    BusinessModel? business,
    String? fallbackBusinessName,
  }) async {
    final resolved = business ?? DashboardSession.activeBusiness.value;
    final name = _safeText(
      (resolved?.name.trim().isNotEmpty == true)
          ? resolved!.name.trim()
          : ((fallbackBusinessName?.trim().isNotEmpty == true) ? fallbackBusinessName!.trim() : 'Admivida POS'),
    );
    final logo = await _tryLoadLogo(resolved?.image?.url);
    final meta = _extractMetadataLines(resolved);
    return (business: resolved, name: name, logo: logo, meta: meta);
  }

  // ===========================================================================
  // SHARED DOLIBARR-STYLE PDF BLOCKS
  // ===========================================================================

  static pw.Widget _buildDocumentHeader({
    required String businessName,
    required pw.ImageProvider? logoImage,
    required String docTitle,
    required String folio,
    required List<String> rightSubLines,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoImage != null) ...[
                pw.Container(
                  constraints: const pw.BoxConstraints(maxWidth: 58, maxHeight: 44),
                  margin: const pw.EdgeInsets.only(right: 10),
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              ],
              pw.Expanded(
                child: pw.Text(
                  businessName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: _brandTeal,
                  ),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              _safeText(docTitle),
              style: pw.TextStyle(fontSize: 13.5, fontWeight: pw.FontWeight.bold, color: _textDark),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Ref. : #$folio',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _textDark),
            ),
            for (final line in rightSubLines)
              pw.Text(_safeText(line), style: pw.TextStyle(fontSize: 9, color: _textMuted)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildEmitterAndRecipientBoxes({
    required BusinessModel? business,
    required String businessName,
    required List<String> metadataLines,
    required String recipientLabel,
    required String recipientTitle,
    List<String> recipientLines = const [],
    String? recipientAlert,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Emisor:', style: pw.TextStyle(fontSize: 9, color: _textDark)),
              pw.SizedBox(height: 4),
              pw.Container(
                width: double.infinity,
                constraints: const pw.BoxConstraints(minHeight: 72),
                padding: const pw.EdgeInsets.all(9),
                color: _emitterBg,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      businessName,
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _textDark),
                    ),
                    if (business?.categoryName.trim().isNotEmpty == true) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        _safeText(business!.categoryName.trim()),
                        style: pw.TextStyle(fontSize: 8.5, color: _textMuted),
                      ),
                    ],
                    if (business?.description?.trim().isNotEmpty == true) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        _safeText(business!.description!.trim()),
                        style: pw.TextStyle(fontSize: 8.5, color: _textMuted),
                      ),
                    ],
                    for (final line in metadataLines) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(line, style: pw.TextStyle(fontSize: 8.5, color: _textDark)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 14),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(_safeText(recipientLabel), style: pw.TextStyle(fontSize: 9, color: _textDark)),
              pw.SizedBox(height: 4),
              pw.Container(
                width: double.infinity,
                constraints: const pw.BoxConstraints(minHeight: 72),
                padding: const pw.EdgeInsets.all(9),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _borderColor, width: 0.7),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _safeText(recipientTitle),
                      style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _textDark),
                    ),
                    for (final line in recipientLines) ...[
                      pw.SizedBox(height: 3),
                      pw.Text(_safeText(line), style: pw.TextStyle(fontSize: 8.5, color: _textMuted)),
                    ],
                    if (recipientAlert != null && recipientAlert.trim().isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _safeText(recipientAlert),
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#B45309'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPageFooter(pw.Context context, String footerLeftText) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _subtleBorder, width: 0.6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(_safeText(footerLeftText), style: pw.TextStyle(fontSize: 8, color: _textMuted)),
          pw.Text('Pagina ${context.pageNumber} de ${context.pagesCount}', style: pw.TextStyle(fontSize: 8, color: _textMuted)),
        ],
      ),
    );
  }

  static pw.Widget _buildNotesBox(String label, String notes) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _borderColor, width: 0.7)),
      child: pw.Text(_safeText('$label: $notes'), style: pw.TextStyle(fontSize: 9, color: _textDark)),
    );
  }

  static pw.Widget _tableHeaderCell(String label, {required pw.TextAlign align}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        _safeText(label),
        textAlign: align,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _textDark),
      ),
    );
  }

  static pw.Widget _tableBodyCell(
    String value, {
    required pw.TextAlign align,
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        _safeText(value),
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? _textDark,
        ),
      ),
    );
  }

  static pw.Widget _totalRow(
    String label,
    String value, {
    required PdfColor textDark,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            _safeText(label),
            style: pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: textDark),
          ),
          pw.Text(
            _safeText(value),
            style: pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: textDark),
          ),
        ],
      ),
    );
  }

  static pw.Widget _highlightedTotalRow(String label, String value) {
    return pw.Container(
      color: _emitterBg,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(_safeText(label), style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _textDark)),
          pw.Text(_safeText(value), style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _textDark)),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. SALE RECEIPT PDF
  // ===========================================================================

  static String buildSalePdfFileName(SaleModel sale) {
    final datePart = DateFormat('yyyyMMdd_HHmm').format(sale.effectiveDate.toLocal());
    return 'Nota_${_shortFolio(sale.id)}_$datePart.pdf';
  }

  static Future<Uint8List> buildSalePdfBytes({
    required SaleModel sale,
    BusinessModel? business,
    String? fallbackBusinessName,
  }) async {
    final ctx = await _resolveBusinessContext(
      business: business,
      fallbackBusinessName: fallbackBusinessName,
    );

    final pdf = pw.Document(
      title: 'Nota ${_shortFolio(sale.id)}',
      author: ctx.name,
      creator: 'Admivida POS',
    );

    final dateFormatted = DateFormat('dd/MM/yyyy hh:mm a').format(sale.effectiveDate.toLocal());
    final folio = _shortFolio(sale.id);
    final docTitle = _saleDocumentTitle(sale.status);
    final statusText = _saleStatusLabel(sale.status);

    final linesSubtotal = sale.details.fold<double>(
      0.0,
      (sum, d) => sum + (d.isPaid ? (d.productPriceSnapshot * d.quantity) : 0.0),
    );
    final total = sale.totalPriceSnapshot;
    final amountPaid = sale.amountPaid ?? 0.0;
    final changeGiven = sale.changeGiven ?? (amountPaid > total ? amountPaid - total : 0.0);
    final isCreditOrLayaway = sale.status.toUpperCase() == 'CREDIT' || sale.status.toUpperCase() == 'LAYAWAY';
    final pendingBalance = (isCreditOrLayaway && total > amountPaid) ? (total - amountPaid) : 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        footer: (context) => _buildPageFooter(context, 'Gracias por su preferencia  |  Folio: ${sale.id}'),
        build: (context) => [
          _buildDocumentHeader(
            businessName: ctx.name,
            logoImage: ctx.logo,
            docTitle: docTitle,
            folio: folio,
            rightSubLines: ['Fecha : $dateFormatted', 'Estatus : $statusText'],
          ),
          pw.SizedBox(height: 16),
          _buildEmitterAndRecipientBoxes(
            business: ctx.business,
            businessName: ctx.name,
            metadataLines: ctx.meta,
            recipientLabel: 'Cliente / Receptor:',
            recipientTitle: sale.clientNameSnapshot.trim().isNotEmpty ? sale.clientNameSnapshot.trim() : 'Publico General',
            recipientLines: [
              if (sale.sellerName?.trim().isNotEmpty == true) 'Atendio: ${sale.sellerName!.trim()}',
            ],
            recipientAlert: sale.id.startsWith('OFFLINE-') ? 'Registro offline pendiente de sincronizar' : null,
          ),
          if (sale.notes != null && sale.notes!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _buildNotesBox('Notas', sale.notes!.trim()),
          ],
          pw.SizedBox(height: 10),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Importes expresados en Moneda Nacional (MXN)',
              style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: _textMuted),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.symmetric(
              inside: pw.BorderSide(color: _borderColor, width: 0.5),
              outside: pw.BorderSide(color: _borderColor, width: 0.8),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(4.5),
              1: pw.FlexColumnWidth(1.4),
              2: pw.FlexColumnWidth(1.0),
              3: pw.FlexColumnWidth(1.1),
              4: pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: _headerBg,
                  border: pw.Border(bottom: pw.BorderSide(color: _borderColor, width: 0.8)),
                ),
                children: [
                  _tableHeaderCell('Descripcion', align: pw.TextAlign.left),
                  _tableHeaderCell('P.U.', align: pw.TextAlign.right),
                  _tableHeaderCell('Cant.', align: pw.TextAlign.right),
                  _tableHeaderCell('Dto.', align: pw.TextAlign.center),
                  _tableHeaderCell('Importe', align: pw.TextAlign.right),
                ],
              ),
              ...sale.details.map((detail) {
                final lineAmount = detail.isPaid ? (detail.productPriceSnapshot * detail.quantity) : 0.0;
                final hasLineDiscount =
                    detail.isPaid && detail.originalPriceSnapshot > detail.productPriceSnapshot + 0.005;
                String discountCell = '';
                if (!detail.isPaid) {
                  discountCell = 'Cortesia';
                } else if (hasLineDiscount && detail.originalPriceSnapshot > 0) {
                  final pct = (((detail.originalPriceSnapshot - detail.productPriceSnapshot) /
                              detail.originalPriceSnapshot) *
                          100)
                      .round();
                  discountCell = pct > 0 ? '$pct%' : 'Oferta';
                }

                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(_safeText(detail.productNameSnapshot), style: pw.TextStyle(fontSize: 9, color: _textDark)),
                          if (detail.commentary != null && detail.commentary!.trim().isNotEmpty)
                            pw.Text(
                              _safeText('Nota: ${detail.commentary!.trim()}'),
                              style: pw.TextStyle(fontSize: 7.5, color: _textMuted),
                            ),
                        ],
                      ),
                    ),
                    _tableBodyCell(_money(detail.productPriceSnapshot), align: pw.TextAlign.right),
                    _tableBodyCell(_formatQty(detail.quantity), align: pw.TextAlign.right),
                    _tableBodyCell(discountCell, align: pw.TextAlign.center, color: _textMuted),
                    _tableBodyCell(_money(lineAmount), align: pw.TextAlign.right, bold: true),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 12,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Forma(s) de pago:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _textDark)),
                    pw.SizedBox(height: 4),
                    if (sale.payments.isNotEmpty)
                      ...sale.payments.map(
                        (p) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 2),
                          child: pw.Text(
                            _safeText('- ${p.paymentMethodName}: ${_money(p.amount)}'),
                            style: pw.TextStyle(fontSize: 8.5, color: _textDark),
                          ),
                        ),
                      )
                    else
                      pw.Text(
                        isCreditOrLayaway ? '- Venta a credito / apartado' : '- Pago directo en caja',
                        style: pw.TextStyle(fontSize: 8.5, color: _textDark),
                      ),
                    if (amountPaid > 0) ...[
                      pw.SizedBox(height: 4),
                      pw.Text('Monto recibido: ${_money(amountPaid)}', style: pw.TextStyle(fontSize: 8.5, color: _textMuted)),
                    ],
                    if (changeGiven > 0.005) ...[
                      pw.SizedBox(height: 2),
                      pw.Text('Cambio devuelto: ${_money(changeGiven)}', style: pw.TextStyle(fontSize: 8.5, color: _textMuted)),
                    ],
                    if (pendingBalance > 0.005) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Saldo pendiente por cubrir: ${_money(pendingBalance)}',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#B45309')),
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                flex: 9,
                child: pw.Column(
                  children: [
                    _totalRow('Subtotal', _money(linesSubtotal), textDark: _textDark),
                    if (sale.discountAmount > 0.005)
                      _totalRow('Descuento global', '-${_money(sale.discountAmount)}', textDark: _textDark),
                    _highlightedTotalRow('Total', _money(total)),
                    if (amountPaid > 0) _totalRow('Pagado', _money(amountPaid), textDark: _textMuted),
                    if (changeGiven > 0.005) _totalRow('Cambio', _money(changeGiven), textDark: _textMuted),
                    if (pendingBalance > 0.005)
                      _totalRow('Saldo pendiente', _money(pendingBalance), textDark: PdfColor.fromHex('#B45309'), bold: true),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ===========================================================================
  // 2. CLIENT PAYMENT (ABONO) RECEIPT PDF
  // ===========================================================================

  static String buildClientPaymentPdfFileName(ClientPaymentResponse payment) {
    final datePart = DateFormat('yyyyMMdd_HHmm').format(payment.paidAt.toLocal());
    return 'Abono_${_shortFolio(payment.receiptId)}_$datePart.pdf';
  }

  static Future<Uint8List> buildClientPaymentPdfBytes({
    required ClientPaymentResponse payment,
    required String clientName,
    required String cashierName,
    BusinessModel? business,
    String? fallbackBusinessName,
  }) async {
    final ctx = await _resolveBusinessContext(
      business: business,
      fallbackBusinessName: fallbackBusinessName,
    );

    final pdf = pw.Document(
      title: 'Abono ${_shortFolio(payment.receiptId)}',
      author: ctx.name,
      creator: 'Admivida POS',
    );

    final dateFormatted = DateFormat('dd/MM/yyyy hh:mm a').format(payment.paidAt.toLocal());
    final folio = _shortFolio(payment.receiptId.isNotEmpty ? payment.receiptId : 'ABONO');
    final isLiquidated = payment.remainingTotalDebt <= 0.01;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        footer: (context) => _buildPageFooter(
          context,
          '${isLiquidated ? 'Cuenta liquidada - Gracias por su abono' : 'Gracias por su abono'}  |  Folio: ${payment.receiptId}',
        ),
        build: (context) => [
          _buildDocumentHeader(
            businessName: ctx.name,
            logoImage: ctx.logo,
            docTitle: 'COMPROBANTE DE ABONO',
            folio: folio,
            rightSubLines: [
              'Fecha : $dateFormatted',
              'Estatus : ${isLiquidated ? 'Cuenta Liquidada' : 'Abono Aplicado'}',
            ],
          ),
          pw.SizedBox(height: 16),
          _buildEmitterAndRecipientBoxes(
            business: ctx.business,
            businessName: ctx.name,
            metadataLines: ctx.meta,
            recipientLabel: 'Cliente:',
            recipientTitle: clientName.trim().isNotEmpty ? clientName.trim() : 'Cliente',
            recipientLines: [
              'Recibio: ${cashierName.trim().isNotEmpty ? cashierName.trim() : 'Cajero'}',
              if (payment.accountName?.trim().isNotEmpty == true) 'Cuenta destino: ${payment.accountName!.trim()}',
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Importes expresados en Moneda Nacional (MXN)',
              style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: _textMuted),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.symmetric(
              inside: pw.BorderSide(color: _borderColor, width: 0.5),
              outside: pw.BorderSide(color: _borderColor, width: 0.8),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(4.2),
              1: pw.FlexColumnWidth(1.6),
              2: pw.FlexColumnWidth(1.6),
              3: pw.FlexColumnWidth(1.6),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: _headerBg,
                  border: pw.Border(bottom: pw.BorderSide(color: _borderColor, width: 0.8)),
                ),
                children: [
                  _tableHeaderCell('Ticket / Concepto', align: pw.TextAlign.left),
                  _tableHeaderCell('Saldo Anterior', align: pw.TextAlign.right),
                  _tableHeaderCell('Abono', align: pw.TextAlign.right),
                  _tableHeaderCell('Saldo Restante', align: pw.TextAlign.right),
                ],
              ),
              if (payment.appliedTickets.isNotEmpty)
                ...payment.appliedTickets.map((ticket) {
                  final shortTicket = _shortFolio(ticket.saleId);
                  final statusNote = ticket.remainingBalance <= 0.01 ? 'Liquidado' : 'Pendiente';
                  return pw.TableRow(
                    children: [
                      _tableBodyCell('Nota #$shortTicket ($statusNote)', align: pw.TextAlign.left),
                      _tableBodyCell(_money(ticket.previousBalance), align: pw.TextAlign.right, color: _textMuted),
                      _tableBodyCell(_money(ticket.amountPaid), align: pw.TextAlign.right, bold: true),
                      _tableBodyCell(_money(ticket.remainingBalance), align: pw.TextAlign.right),
                    ],
                  );
                })
              else
                pw.TableRow(
                  children: [
                    _tableBodyCell('Abono a cuenta (${payment.ticketsImpacted} nota(s))', align: pw.TextAlign.left),
                    _tableBodyCell(_money(payment.previousTotalDebt), align: pw.TextAlign.right, color: _textMuted),
                    _tableBodyCell(_money(payment.totalPaid), align: pw.TextAlign.right, bold: true),
                    _tableBodyCell(_money(payment.remainingTotalDebt), align: pw.TextAlign.right),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 12,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Forma(s) de pago:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _textDark)),
                    pw.SizedBox(height: 4),
                    if (payment.payments.isNotEmpty)
                      ...payment.payments.map(
                        (p) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 2),
                          child: pw.Text(
                            _safeText('- ${p.paymentMethodName}: ${_money(p.amount)}'),
                            style: pw.TextStyle(fontSize: 8.5, color: _textDark),
                          ),
                        ),
                      )
                    else
                      pw.Text('- Pago registrado en caja', style: pw.TextStyle(fontSize: 8.5, color: _textDark)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Notas impactadas: ${payment.ticketsImpacted}',
                      style: pw.TextStyle(fontSize: 8.5, color: _textMuted),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                flex: 9,
                child: pw.Column(
                  children: [
                    _totalRow('Adeudo anterior', _money(payment.previousTotalDebt), textDark: _textMuted),
                    _highlightedTotalRow('Total Abonado', _money(payment.totalPaid)),
                    _totalRow(
                      'Saldo restante',
                      _money(payment.remainingTotalDebt),
                      textDark: isLiquidated ? PdfColor.fromHex('#0F766E') : PdfColor.fromHex('#B45309'),
                      bold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ===========================================================================
  // 3. CASH SHIFT CUT (CORTE X / Z) PDF
  // ===========================================================================

  static String buildShiftCutPdfFileName(CashShiftModel shift) {
    final refDate = (shift.closedAt ?? DateTime.now()).toLocal();
    final datePart = DateFormat('yyyyMMdd_HHmm').format(refDate);
    final kind = shift.isOpen ? 'CorteX' : 'CorteZ';
    return '${kind}_${_shortFolio(shift.id)}_$datePart.pdf';
  }

  static Future<Uint8List> buildShiftCutPdfBytes({
    required CashShiftModel shift,
    BusinessModel? business,
    String? fallbackBusinessName,
  }) async {
    final ctx = await _resolveBusinessContext(
      business: business,
      fallbackBusinessName: fallbackBusinessName,
    );

    final pdf = pw.Document(
      title: '${shift.isOpen ? 'Corte X' : 'Corte Z'} ${_shortFolio(shift.id)}',
      author: ctx.name,
      creator: 'Admivida POS',
    );

    final openedStr = DateFormat('dd/MM/yyyy hh:mm a').format(shift.openedAt.toLocal());
    final closedStr = shift.closedAt != null
        ? DateFormat('dd/MM/yyyy hh:mm a').format(shift.closedAt!.toLocal())
        : 'Turno abierto (Corte Parcial)';
    final folio = _shortFolio(shift.id);
    final docTitle = shift.isOpen ? 'CORTE PARCIAL DE CAJA (X)' : 'CORTE DE CAJA (Z)';
    final totalIncome = (shift.cashSales ?? 0) + (shift.expectedCard ?? 0) + (shift.expectedTransfer ?? 0);

    final summaryRows = <({String concept, String value, bool bold})>[
      (concept: 'Fondo Inicial de Caja', value: _money(shift.openingAmount), bold: false),
      (concept: '(+) Entradas Manuales de Efectivo', value: _money(shift.manualIn), bold: false),
      (concept: '(-) Retiros / Salidas de Efectivo', value: _money(shift.manualOut), bold: false),
    ];

    if (shift.isBlindMode) {
      summaryRows.add((concept: 'Total de Ventas Registradas', value: '${shift.salesCount}', bold: false));
      if (shift.actualCash != null) {
        summaryRows.add((concept: 'Efectivo Fisico Contado al Cierre', value: _money(shift.actualCash!), bold: true));
      }
    } else {
      summaryRows.addAll([
        (concept: '(+) Ventas en Efectivo', value: _money(shift.cashSales ?? 0), bold: false),
        if ((shift.clientPaymentsCount ?? 0) > 0)
          (
            concept: '    Incluye Abonos de Clientes (${shift.clientPaymentsCount})',
            value: _money(shift.clientPaymentsTotal ?? 0),
            bold: false,
          ),
        (concept: 'Efectivo Esperado en Caja', value: _money(shift.expectedCash ?? 0), bold: true),
        if (shift.actualCash != null)
          (concept: 'Efectivo Contado por Cajero', value: _money(shift.actualCash!), bold: true),
        if (shift.actualCash != null)
          (
            concept: 'Diferencia (Contado vs Esperado)',
            value: '${(shift.difference ?? 0) > 0 ? '+' : ''}${_money(shift.difference ?? 0)}',
            bold: true,
          ),
        (concept: 'Ingresos con Tarjeta', value: _money(shift.expectedCard ?? 0), bold: false),
        (concept: 'Ingresos por Transferencia', value: _money(shift.expectedTransfer ?? 0), bold: false),
        (concept: 'Total General de Ingresos (Efectivo + Tarjeta + Transf.)', value: _money(totalIncome), bold: true),
        (concept: 'Tickets Procesados', value: '${shift.salesCount}', bold: false),
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        footer: (context) => _buildPageFooter(context, 'Comprobante de corte de caja  |  Turno ID: ${shift.id}'),
        build: (context) => [
          _buildDocumentHeader(
            businessName: ctx.name,
            logoImage: ctx.logo,
            docTitle: docTitle,
            folio: folio,
            rightSubLines: ['Apertura : $openedStr', 'Cierre : $closedStr'],
          ),
          pw.SizedBox(height: 16),
          _buildEmitterAndRecipientBoxes(
            business: ctx.business,
            businessName: ctx.name,
            metadataLines: ctx.meta,
            recipientLabel: 'Caja / Turno:',
            recipientTitle: shift.accountName?.trim().isNotEmpty == true ? shift.accountName!.trim() : 'Caja Principal',
            recipientLines: [
              'Cajero: ${shift.cashierName?.trim().isNotEmpty == true ? shift.cashierName!.trim() : 'Cajero'}',
              'Estado: ${shift.isOpen ? 'Turno Abierto' : 'Turno Cerrado'}',
            ],
            recipientAlert: shift.isBlindMode ? 'Modo ciego activo (arqueo sin totales esperados)' : null,
          ),
          if (shift.notes != null && shift.notes!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _buildNotesBox('Notas de cierre', shift.notes!.trim()),
          ],
          pw.SizedBox(height: 12),
          pw.Text('Resumen Financiero del Turno', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _textDark)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.symmetric(
              inside: pw.BorderSide(color: _borderColor, width: 0.5),
              outside: pw.BorderSide(color: _borderColor, width: 0.8),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(4.5),
              1: pw.FlexColumnWidth(1.8),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: _headerBg,
                  border: pw.Border(bottom: pw.BorderSide(color: _borderColor, width: 0.8)),
                ),
                children: [
                  _tableHeaderCell('Concepto', align: pw.TextAlign.left),
                  _tableHeaderCell('Importe / Cantidad', align: pw.TextAlign.right),
                ],
              ),
              ...summaryRows.map(
                (row) => pw.TableRow(
                  decoration: row.bold ? pw.BoxDecoration(color: PdfColor.fromHex('#F9FAFB')) : null,
                  children: [
                    _tableBodyCell(row.concept, align: pw.TextAlign.left, bold: row.bold),
                    _tableBodyCell(row.value, align: pw.TextAlign.right, bold: row.bold),
                  ],
                ),
              ),
            ],
          ),
          if (shift.movements.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text('Movimientos Manuales de Efectivo', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _textDark)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.symmetric(
                inside: pw.BorderSide(color: _borderColor, width: 0.5),
                outside: pw.BorderSide(color: _borderColor, width: 0.8),
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.2),
                1: pw.FlexColumnWidth(3.6),
                2: pw.FlexColumnWidth(1.6),
                3: pw.FlexColumnWidth(1.4),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: _headerBg,
                    border: pw.Border(bottom: pw.BorderSide(color: _borderColor, width: 0.8)),
                  ),
                  children: [
                    _tableHeaderCell('Tipo', align: pw.TextAlign.center),
                    _tableHeaderCell('Concepto', align: pw.TextAlign.left),
                    _tableHeaderCell('Hora', align: pw.TextAlign.center),
                    _tableHeaderCell('Monto', align: pw.TextAlign.right),
                  ],
                ),
                ...shift.movements.map(
                  (mov) => pw.TableRow(
                    children: [
                      _tableBodyCell(mov.isIn ? 'ENTRADA' : 'RETIRO', align: pw.TextAlign.center, bold: true),
                      _tableBodyCell(mov.concept, align: pw.TextAlign.left),
                      _tableBodyCell(
                        DateFormat('dd/MM hh:mm a').format(mov.createdAt.toLocal()),
                        align: pw.TextAlign.center,
                        color: _textMuted,
                      ),
                      _tableBodyCell(
                        '${mov.isIn ? '+' : '-'}${_money(mov.amount)}',
                        align: pw.TextAlign.right,
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  // ===========================================================================
  // SHARED PREVIEW / SHARE / PRINT DIALOG
  // ===========================================================================

  static Future<File> _writeTempPdf(Uint8List bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Opens a Letter-sized PDF preview dialog for a Sale (online or offline).
  static Future<void> showSalePdfPreviewDialog({
    required BuildContext context,
    required SaleModel sale,
    BusinessModel? business,
    String? fallbackBusinessName,
  }) {
    final fileName = buildSalePdfFileName(sale);
    return _showPdfPreviewDialog(
      context: context,
      title: 'Comprobante PDF (Tamaño Carta)',
      subtitle: 'Folio #${_shortFolio(sale.id)} • ${sale.clientNameSnapshot}',
      fileName: fileName,
      buildBytes: () => buildSalePdfBytes(
        sale: sale,
        business: business,
        fallbackBusinessName: fallbackBusinessName,
      ),
    );
  }

  /// Opens a Letter-sized PDF preview dialog for a Client Debt Payment (Abono).
  static Future<void> showClientPaymentPdfPreviewDialog({
    required BuildContext context,
    required ClientPaymentResponse payment,
    required String clientName,
    required String cashierName,
    BusinessModel? business,
    String? fallbackBusinessName,
  }) {
    final fileName = buildClientPaymentPdfFileName(payment);
    return _showPdfPreviewDialog(
      context: context,
      title: 'Comprobante de Abono PDF',
      subtitle: 'Folio #${_shortFolio(payment.receiptId)} • $clientName',
      fileName: fileName,
      buildBytes: () => buildClientPaymentPdfBytes(
        payment: payment,
        clientName: clientName,
        cashierName: cashierName,
        business: business,
        fallbackBusinessName: fallbackBusinessName,
      ),
    );
  }

  /// Opens a Letter-sized PDF preview dialog for a Cash Shift Cut (X / Z).
  static Future<void> showShiftCutPdfPreviewDialog({
    required BuildContext context,
    required CashShiftModel shift,
    BusinessModel? business,
    String? fallbackBusinessName,
  }) {
    final fileName = buildShiftCutPdfFileName(shift);
    final label = shift.isOpen ? 'Corte Parcial (X) PDF' : 'Corte de Caja (Z) PDF';
    return _showPdfPreviewDialog(
      context: context,
      title: label,
      subtitle: 'Turno #${_shortFolio(shift.id)} • ${shift.cashierName ?? 'Cajero'}',
      fileName: fileName,
      buildBytes: () => buildShiftCutPdfBytes(
        shift: shift,
        business: business,
        fallbackBusinessName: fallbackBusinessName,
      ),
    );
  }

  static Future<void> _showPdfPreviewDialog({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String fileName,
    required Future<Uint8List> Function() buildBytes,
  }) async {
    Uint8List? cachedBytes;

    Future<Uint8List> getBytes() async {
      cachedBytes ??= await buildBytes();
      return cachedBytes!;
    }

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final size = MediaQuery.sizeOf(dialogContext);
        final isWide = size.width >= 760;
        bool isWorking = false;

        return StatefulBuilder(
          builder: (ctx, setModalState) => Dialog(
            insetPadding: EdgeInsets.symmetric(
              horizontal: isWide ? 48 : 12,
              vertical: isWide ? 28 : 18,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 780,
                maxHeight: size.height * 0.9,
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    color: AppColors.kPrimaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 22),
                        const Gap(10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                subtitle,
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          tooltip: 'Cerrar',
                        ),
                      ],
                    ),
                  ),

                  // Preview area
                  Expanded(
                    child: PdfPreview(
                      build: (_) => getBytes(),
                      initialPageFormat: PdfPageFormat.letter,
                      canChangePageFormat: false,
                      canChangeOrientation: false,
                      canDebug: false,
                      useActions: false,
                      pdfFileName: fileName,
                      loadingWidget: const Center(child: CircularProgressIndicator()),
                    ),
                  ),

                  // Action Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.kNeutral50,
                      border: Border(top: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: isWorking
                              ? null
                              : () async {
                                  setModalState(() => isWorking = true);
                                  try {
                                    final bytes = await getBytes();
                                    final file = await _writeTempPdf(bytes, fileName);
                                    await OpenFilex.open(file.path);
                                  } catch (e) {
                                    AppLogger.error('Error abriendo PDF: $e');
                                    if (dialogContext.mounted) {
                                      SnackbarUtil.showError(dialogContext, 'No se pudo abrir el archivo PDF');
                                    }
                                  } finally {
                                    if (ctx.mounted) setModalState(() => isWorking = false);
                                  }
                                },
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text('Abrir / Guardar PDF'),
                        ),
                        OutlinedButton.icon(
                          onPressed: isWorking
                              ? null
                              : () async {
                                  setModalState(() => isWorking = true);
                                  try {
                                    final bytes = await getBytes();
                                    await Printing.layoutPdf(
                                      onLayout: (_) async => bytes,
                                      name: fileName,
                                      format: PdfPageFormat.letter,
                                    );
                                  } catch (e) {
                                    AppLogger.error('Error imprimiendo PDF Carta: $e');
                                    if (dialogContext.mounted) {
                                      SnackbarUtil.showError(dialogContext, 'No se pudo enviar a la impresora');
                                    }
                                  } finally {
                                    if (ctx.mounted) setModalState(() => isWorking = false);
                                  }
                                },
                          icon: const Icon(Icons.print_rounded, size: 18),
                          label: const Text('Imprimir Carta'),
                        ),
                        ElevatedButton.icon(
                          onPressed: isWorking
                              ? null
                              : () async {
                                  setModalState(() => isWorking = true);
                                  try {
                                    final bytes = await getBytes();
                                    final shared = await Printing.sharePdf(bytes: bytes, filename: fileName);
                                    if (!shared) {
                                      final file = await _writeTempPdf(bytes, fileName);
                                      await OpenFilex.open(file.path);
                                    }
                                  } catch (e) {
                                    AppLogger.error('Error compartiendo PDF: $e');
                                    if (dialogContext.mounted) {
                                      SnackbarUtil.showError(dialogContext, 'No se pudo compartir el archivo PDF');
                                    }
                                  } finally {
                                    if (ctx.mounted) setModalState(() => isWorking = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text('Compartir / WhatsApp'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
