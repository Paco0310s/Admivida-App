enum CommissionType {
  percentage('PERCENTAGE'),
  fixedAmount('FIXED_AMOUNT'),
  noCommission('NO_COMMISSION');

  final String value;
  const CommissionType(this.value);

  // Helper to parse from backend JSON
  factory CommissionType.fromString(String value) {
    return values.firstWhere((e) => e.value == value, orElse: () => CommissionType.noCommission);
  }
}
