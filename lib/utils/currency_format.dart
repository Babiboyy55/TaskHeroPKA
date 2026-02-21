/// Định dạng số thành chuỗi tiền VNĐ, ví dụ: 20000 → "20.000đ"
String formatVND(num amount) {
  final intAmount = amount.toInt();
  final str = intAmount.abs().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(str[i]);
  }
  return (intAmount < 0 ? '-' : '') + buffer.toString() + 'đ';
}
