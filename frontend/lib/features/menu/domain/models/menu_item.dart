class MenuItem {
  final String id;
  final String name;
  final int price;
  final String imageUrl;
  final bool isEnabled;
  final int stock;
  final String? kemitraan;
  final String? subBrand;

  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.isEnabled,
    required this.stock,
    this.kemitraan,
    this.subBrand,
  });

  // Status logic
  MenuStatus get status {
    if (!isEnabled) return MenuStatus.notAvailed;
    if (stock == 0) return MenuStatus.outOfStock;
    return MenuStatus.availed;
  }

  String get statusLabel {
    switch (status) {
      case MenuStatus.availed:
        return 'Availed';
      case MenuStatus.outOfStock:
        return 'Out of Stock';
      case MenuStatus.notAvailed:
        return 'Not Availed';
    }
  }

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? '').toString(),
      price: _parsePrice(json['price']),
      imageUrl: _parseImage(json),
      isEnabled:
          json['is_active'] ?? json['isEnabled'] ?? json['is_enabled'] ?? true,
      stock: json['stock'] ?? 0,
      kemitraan: json['kemitraan']?.toString(),
      subBrand: (json['subBrand'] ?? json['sub_brand'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'isEnabled': isEnabled,
      'stock': stock,
      if (kemitraan != null) 'kemitraan': kemitraan,
      if (subBrand != null) 'subBrand': subBrand,
    };
  }

  MenuItem copyWith({
    String? id,
    String? name,
    int? price,
    String? imageUrl,
    bool? isEnabled,
    int? stock,
    String? kemitraan,
    String? subBrand,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isEnabled: isEnabled ?? this.isEnabled,
      stock: stock ?? this.stock,
      kemitraan: kemitraan ?? this.kemitraan,
      subBrand: subBrand ?? this.subBrand,
    );
  }

  static int _parsePrice(dynamic priceRaw) {
    if (priceRaw == null) return 0;
    if (priceRaw is int) return priceRaw;
    if (priceRaw is double) return priceRaw.toInt();
    return int.tryParse(priceRaw.toString()) ?? 0;
  }

  static String _parseImage(Map<String, dynamic> json) {
    final imageData = json['imageData'] ?? json['image_data'];
    if (imageData != null && imageData.toString().isNotEmpty) {
      return imageData.toString();
    }
    return (json['imageUrl'] ?? json['image_url'] ?? '').toString();
  }

  String get priceLabel => 'Rp ${_formatPrice(price)}';

  static String _formatPrice(int value) {
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

enum MenuStatus { availed, outOfStock, notAvailed }
