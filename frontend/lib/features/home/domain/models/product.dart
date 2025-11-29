class Product {
  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.imageAsset,
    this.stock = 0,
    this.isEnabled = true,
  });

  final String id;
  final String title;
  final int price; // in Rupiah
  final String imageAsset;
  final int stock;
  final bool isEnabled;

  String get priceLabel => 'Rp ${_formatSimple(price)}';

  static String _formatSimple(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      buffer.write(s[i]);
      final remaining = s.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
    }
    return buffer.toString();
  }
}
