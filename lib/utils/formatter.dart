import 'package:intl/intl.dart';

String formatRupiah(double amount) {
  final format = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return format.format(amount);
}

String formatDate(String isoString) {
  final date = DateTime.parse(isoString);
  final format = DateFormat('dd MMM yyyy', 'id_ID');
  return format.format(date);
}

String formatDateTime(String isoString) {
  final date = DateTime.parse(isoString);
  final format = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  return format.format(date);
}

String nowIso() => DateTime.now().toIso8601String();
