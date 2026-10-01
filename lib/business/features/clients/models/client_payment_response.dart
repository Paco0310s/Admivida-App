class ClientPaymentResponse {
  final String message;
  final double totalPaid;
  final int ticketsImpacted;

  ClientPaymentResponse({required this.message, required this.totalPaid, required this.ticketsImpacted});

  factory ClientPaymentResponse.fromJson(Map<String, dynamic> json) {
    return ClientPaymentResponse(
      message: json['message'] as String? ?? '',
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0.0,
      ticketsImpacted: json['ticketsImpacted'] as int? ?? 0,
    );
  }
}
