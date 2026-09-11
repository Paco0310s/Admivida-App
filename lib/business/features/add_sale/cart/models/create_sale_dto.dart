import 'package:admivida/business/features/add_sale/models/create_sale_detail_inner_dto.dart';

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
    };
  }
}
