class FormattersUtil {
  // Format currency with commas and 2 decimal places
  static String formatWithCommas(double amount) {
    return '\$${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }
}
