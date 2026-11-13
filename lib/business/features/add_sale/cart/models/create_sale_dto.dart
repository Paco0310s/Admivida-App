import 'package:admivida/business/features/add_sale/models/create_sale_detail_inner_dto.dart';

class CreateSalePaymentDto {
  final String paymentMethodId;
  final double amount;
  final String? accountId;
  final String? paymentMethodName; // Solo UI / preview offline

  const CreateSalePaymentDto({
    required this.paymentMethodId,
    required this.amount,
    this.accountId,
    this.paymentMethodName,
  });

  Map<String, dynamic> toJson() {
    return {
      'paymentMethodId': paymentMethodId,
      'amount': amount,
      if (accountId != null) 'accountId': accountId,
    };
  }

  Map<String, dynamic> toLocalJson() {
    return {
      ...toJson(),
      if (paymentMethodName != null) 'paymentMethodName': paymentMethodName,
    };
  }

  factory CreateSalePaymentDto.fromJson(Map<String, dynamic> json) {
    return CreateSalePaymentDto(
      paymentMethodId: json['paymentMethodId'] as String? ?? '',
      amount: (json['amount'] as num? ?? 0).toDouble(),
      accountId: json['accountId'] as String?,
      paymentMethodName: json['paymentMethodName'] as String?,
    );
  }
}

class CreateSaleDto {
  final String businessId;
  final String sellerUserId;
  final String accountId;
  final String paymentMethodId;
  final String? clientUserId;
  final String clientNameSnapshot;
  final String status;
  final double discountAmount;
  final double amountPaid;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final DateTime? soldAt;
  final List<CreateSaleDetailInnerDto> details;
  final List<CreateSalePaymentDto>? payments;

  CreateSaleDto({
    required this.businessId,
    required this.sellerUserId,
    required this.accountId,
    required this.paymentMethodId,
    this.clientUserId,
    required this.clientNameSnapshot,
    required this.status,
    required this.discountAmount,
    required this.amountPaid,
    this.notes,
    this.latitude,
    this.longitude,
    this.soldAt,
    required this.details,
    this.payments,
  });

  /// Converts the DTO into a JSON map for the HTTP request
  Map<String, dynamic> toJson() {
    return {
      "businessId": businessId,
      "sellerUserId": sellerUserId,
      "accountId": accountId,
      "paymentMethodId": paymentMethodId,
      if (clientUserId != null) "clientUserId": clientUserId,
      "clientNameSnapshot": clientNameSnapshot.isEmpty ? 'Público General' : clientNameSnapshot,
      "status": status,
      "discountAmount": discountAmount,
      "amountPaid": amountPaid,
      if (notes != null && notes!.trim().isNotEmpty) "notes": notes!.trim(),
      if (latitude != null) "latitude": latitude,
      if (longitude != null) "longitude": longitude,
      if (soldAt != null) "sold_at": soldAt!.toIso8601String(),

      // Aprovechamos el método toJson que ya tienes en CreateSaleDetailInnerDto.
      // ¡Es la forma más limpia!
      "details": details.map((item) => item.toJson()).toList(),
      if (payments != null && payments!.isNotEmpty)
        "payments": payments!.map((p) => p.toJson()).toList(),
    };
  }

  factory CreateSaleDto.fromJson(Map<String, dynamic> json) {
    final rawDetails = json['details'] as List<dynamic>? ?? const [];
    final rawPayments = json['payments'] as List<dynamic>?;
    return CreateSaleDto(
      businessId: json['businessId'] as String? ?? '',
      sellerUserId: json['sellerUserId'] as String? ?? '',
      accountId: json['accountId'] as String? ?? '',
      paymentMethodId: json['paymentMethodId'] as String? ?? '',
      clientUserId: json['clientUserId'] as String?,
      clientNameSnapshot: json['clientNameSnapshot'] as String? ?? 'Público General',
      status: json['status'] as String? ?? 'COMPLETED',
      discountAmount: (json['discountAmount'] as num? ?? 0).toDouble(),
      amountPaid: (json['amountPaid'] as num? ?? 0).toDouble(),
      notes: json['notes'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      soldAt: json['sold_at'] != null ? DateTime.tryParse(json['sold_at'] as String) : null,
      details: rawDetails
          .map((item) => CreateSaleDetailInnerDto.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      payments: rawPayments
          ?.map((p) => CreateSalePaymentDto.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList(),
    );
  }
}
