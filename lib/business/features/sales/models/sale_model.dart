import 'package:admivida/common/models/object_to_print.dart';

class SaleDetailModel {
  final String id;
  final String saleId;
  final String productVariantId;
  final String productNameSnapshot;
  final double quantity;
  final double originalPriceSnapshot;
  final double productPriceSnapshot;
  final double? productCostSnapshot;
  final String priceType;
  final String? commentary;
  final bool isPaid;
  final double sellerComissionSnapshot;
  final bool isComissionPaid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? productId;

  // Campos extra para la UI
  final double subtotal;
  final String? imageUrl;

  const SaleDetailModel({
    required this.id,
    required this.saleId,
    required this.productVariantId,
    required this.productId,
    required this.productNameSnapshot,
    required this.quantity,
    required this.originalPriceSnapshot,
    required this.productPriceSnapshot,
    this.productCostSnapshot,
    required this.priceType,
    this.commentary,
    required this.isPaid,
    required this.sellerComissionSnapshot,
    required this.isComissionPaid,
    required this.createdAt,
    required this.updatedAt,
    required this.subtotal,
    this.imageUrl,
  });

  factory SaleDetailModel.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] as num? ?? 0).toDouble();
    final price = (json['productPriceSnapshot'] as num? ?? 0).toDouble();

    return SaleDetailModel(
      id: json['id'] as String? ?? '',
      saleId: json['saleId'] as String? ?? '',
      productVariantId: json['productVariantId'] as String? ?? '',
      productId: json['productId'] as String?,
      productNameSnapshot: json['productNameSnapshot'] as String? ?? '',
      quantity: qty,
      originalPriceSnapshot: (json['originalPriceSnapshot'] as num? ?? 0).toDouble(),
      productPriceSnapshot: price,
      productCostSnapshot: (json['productCostSnapshot'] as num?)?.toDouble(),
      priceType: json['priceType'] as String? ?? '',
      commentary: json['commentary'] as String?,
      isPaid: json['isPaid'] as bool? ?? false,
      sellerComissionSnapshot: (json['sellerComissionSnapshot'] as num? ?? 0).toDouble(),
      isComissionPaid: json['isComissionPaid'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      // Si el JSON trae subtotal lo usa, si no, lo calcula automáticamente
      subtotal: json['subtotal'] != null ? (json['subtotal'] as num).toDouble() : (qty * price),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'saleId': saleId,
      'productVariantId': productVariantId,
      'productId': productId,
      'productNameSnapshot': productNameSnapshot,
      'quantity': quantity,
      'originalPriceSnapshot': originalPriceSnapshot,
      'productPriceSnapshot': productPriceSnapshot,
      'productCostSnapshot': productCostSnapshot,
      'priceType': priceType,
      'commentary': commentary,
      'isPaid': isPaid,
      'sellerComissionSnapshot': sellerComissionSnapshot,
      'isComissionPaid': isComissionPaid,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'subtotal': subtotal,
      'imageUrl': imageUrl,
    };
  }
}

class SalePaymentModel {
  final String paymentMethodId;
  final String paymentMethodName;
  final String paymentMethodCode;
  final double amount;

  const SalePaymentModel({
    required this.paymentMethodId,
    required this.paymentMethodName,
    required this.paymentMethodCode,
    required this.amount,
  });

  factory SalePaymentModel.fromJson(Map<String, dynamic> json) {
    return SalePaymentModel(
      paymentMethodId: json['paymentMethodId'] as String? ?? '',
      paymentMethodName: json['paymentMethodName'] as String? ?? 'Pago',
      paymentMethodCode: json['paymentMethodCode'] as String? ?? 'OTHER',
      amount: (json['amount'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentMethodId': paymentMethodId,
      'paymentMethodName': paymentMethodName,
      'paymentMethodCode': paymentMethodCode,
      'amount': amount,
    };
  }
}

class SaleModel {
  final String id;
  final String businessId;
  final String sellerUserId;
  final String? sellerName;
  final String? clientUserId;
  final String clientNameSnapshot;
  final String status;
  final double discountAmount;
  final double? amountPaid;
  final double? changeGiven;
  final double totalPriceSnapshot;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final List<SaleDetailModel> details;
  final List<SalePaymentModel> payments;
  final DateTime? soldAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  DateTime get effectiveDate => soldAt ?? createdAt;

  const SaleModel({
    required this.id,
    required this.businessId,
    required this.sellerUserId,
    this.sellerName,
    this.clientUserId,
    required this.clientNameSnapshot,
    required this.status,
    required this.discountAmount,
    this.amountPaid,
    this.changeGiven,
    required this.totalPriceSnapshot,
    this.notes,
    this.latitude,
    this.longitude,
    required this.details,
    this.payments = const [],
    this.soldAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    final rawSoldAt = (json['soldAt'] ?? json['sold_at']) as String?;
    return SaleModel(
      id: json['id'] as String? ?? '',
      businessId: json['businessId'] as String? ?? '',
      sellerUserId: json['sellerUserId'] as String? ?? '',
      sellerName: json['sellerName'] as String?,
      clientUserId: json['clientUserId'] as String?,
      clientNameSnapshot: json['clientNameSnapshot'] as String? ?? 'Público General',
      status: json['status'] as String? ?? '',
      discountAmount: (json['discountAmount'] as num? ?? 0).toDouble(),
      amountPaid: (json['amountPaid'] as num?)?.toDouble(),
      changeGiven: (json['changeGiven'] as num?)?.toDouble(),
      totalPriceSnapshot: (json['totalPriceSnapshot'] as num? ?? 0).toDouble(),
      notes: json['notes'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      details: (json['details'] as List<dynamic>?)?.map((item) => SaleDetailModel.fromJson(item as Map<String, dynamic>)).toList() ?? [],
      payments: (json['payments'] as List<dynamic>?)
              ?.map((item) => SalePaymentModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          const [],
      soldAt: rawSoldAt != null ? DateTime.tryParse(rawSoldAt)?.toLocal() : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'sellerUserId': sellerUserId,
      'sellerName': sellerName,
      'clientUserId': clientUserId,
      'clientNameSnapshot': clientNameSnapshot,
      'status': status,
      'discountAmount': discountAmount,
      'amountPaid': amountPaid,
      'changeGiven': changeGiven,
      'totalPriceSnapshot': totalPriceSnapshot,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
      'details': details.map((d) => d.toJson()).toList(),
      if (payments.isNotEmpty) 'payments': payments.map((p) => p.toJson()).toList(),
      if (soldAt != null) 'soldAt': soldAt!.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ObjectToPrint toObjectToPrint({
    required String businessName,
    bool openDrawer = false,
  }) {
    final List<PrintableRow> ticketRows = details.map((detail) {
      return PrintableRow(
        quantity: detail.quantity,
        description: '${detail.productNameSnapshot}${!detail.isPaid ? ' (No pagado)' : ''}',
        price: detail.productPriceSnapshot,
        total: detail.subtotal,
      );
    }).toList();

    final double calculatedSubtotal = ticketRows.fold(0.0, (sum, row) => sum + row.total);

    return ObjectToPrint(
      businessName: businessName,
      ticketId: id,
      date: effectiveDate,
      cashierName: sellerName ?? 'Cajero Default',
      customerName: clientNameSnapshot,
      rows: ticketRows,
      subtotal: calculatedSubtotal,
      discount: discountAmount,
      total: totalPriceSnapshot,
      amountPaid: amountPaid ?? 0.0,
      changeGiven: changeGiven ?? 0.0,
      payments: payments
          .map((p) => PrintablePayment(methodName: p.paymentMethodName, amount: p.amount))
          .toList(),
      openDrawer: openDrawer,
    );
  }
}
