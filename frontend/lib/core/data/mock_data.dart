import '../../features/products/domain/entities/product.dart';

/// Mock data untuk development UI/UX
/// Digunakan sementara sebelum backend/database siap
class MockData {
  /// Mock products data dengan berbagai kategori
  static List<Product> get mockProducts => [
    // Makanan
    Product(
      id: '1',
      name: 'Nasi Goreng Spesial',
      description: 'Nasi goreng dengan telur, ayam, dan sayuran segar',
      price: 25000,
      category: 'Makanan',
      stock: 50,
      imageUrl:
          'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400',
      isActive: true,
      isBestSeller: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: '2',
      name: 'Mie Goreng',
      description: 'Mie goreng dengan sayuran dan telur',
      price: 20000,
      category: 'Makanan',
      stock: 45,
      imageUrl:
          'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=400',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: '3',
      name: 'Ayam Goreng',
      description: 'Ayam goreng crispy dengan bumbu rahasia',
      price: 30000,
      category: 'Makanan',
      stock: 30,
      imageUrl:
          'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=400',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: '4',
      name: 'Sate Ayam',
      description: '10 tusuk sate ayam dengan bumbu kacang',
      price: 35000,
      category: 'Makanan',
      stock: 25,
      imageUrl:
          'https://images.unsplash.com/photo-1529563021893-cc83c992d75d?w=400',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: '5',
      name: 'Gado-Gado',
      description: 'Sayuran dengan bumbu kacang kental',
      price: 18000,
      category: 'Makanan',
      stock: 40,
      imageUrl:
          'https://images.unsplash.com/photo-1602457260301-1fb75ff295bf?w=400',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    // Minuman
    Product(
      id: '6',
      name: 'Es Teh Manis',
      description: 'Teh manis dingin yang menyegarkan',
      price: 5000,
      category: 'Minuman',
      stock: 100,
      imageUrl:
          'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400',
      isActive: true,
      isBestSeller: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: '7',
      name: 'Es Jeruk',
      description: 'Jus jeruk segar dengan es batu',
      price: 8000,
      category: 'Minuman',
      stock: 80,
      imageUrl:
          'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=400',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: '8',
      name: 'Kopi Susu',
      description: 'Kopi susu dengan gula aren',
      price: 12000,
      category: 'Minuman',
      stock: 60,
      imageUrl:
          'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400',
      isActive: true,
      isBestSeller: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: '9',
      name: 'Jus Alpukat',
      description: 'Jus alpukat segar dengan susu coklat',
      price: 15000,
      category: 'Minuman',
      stock: 35,
      imageUrl:
          'https://images.unsplash.com/photo-1623065422902-30a2d299bbe4?w=400',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: '10',
      name: 'Es Kelapa Muda',
      description: 'Kelapa muda segar dengan es',
      price: 10000,
      category: 'Minuman',
      stock: 50,
      imageUrl:
          'https://images.unsplash.com/photo-1585238342024-78d387f4a707?w=400',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    // Snack
    Product(
      id: '11',
      name: 'Pisang Goreng',
      description: '5 potong pisang goreng crispy',
      price: 10000,
      category: 'Snack',
      stock: 40,
      imageUrl:
          'https://images.unsplash.com/photo-1587241321921-91a834d82ffc?w=400',
      isActive: true,
      isBestSeller: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: '12',
      name: 'Tahu Isi',
      description: 'Tahu goreng isi sayuran',
      price: 12000,
      category: 'Snack',
      stock: 35,
      imageUrl:
          'https://images.unsplash.com/photo-1609501676725-7186f017a4b7?w=400',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: '13',
      name: 'Cireng',
      description: 'Aci digoreng isi bumbu kacang',
      price: 8000,
      category: 'Snack',
      stock: 50,
      imageUrl:
          'https://images.unsplash.com/photo-1599490659213-e2b9527bd087?w=400',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: '14',
      name: 'Bakwan Jagung',
      description: 'Bakwan jagung manis goreng',
      price: 9000,
      category: 'Snack',
      stock: 45,
      imageUrl:
          'https://images.unsplash.com/photo-1612786599419-2c05820bae15?w=400',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: '15',
      name: 'Keripik Tempe',
      description: 'Keripik tempe renyah pedas manis',
      price: 7000,
      category: 'Snack',
      stock: 60,
      imageUrl:
          'https://images.unsplash.com/photo-1599490659213-e2b9527bd087?w=400',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    // Dessert
    Product(
      id: '16',
      name: 'Es Krim Vanilla',
      description: 'Es krim vanilla premium',
      price: 15000,
      category: 'Dessert',
      stock: 30,
      imageUrl:
          'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=400',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: '17',
      name: 'Puding Coklat',
      description: 'Puding coklat lembut dengan saus vanilla',
      price: 12000,
      category: 'Dessert',
      stock: 25,
      imageUrl:
          'https://images.unsplash.com/photo-1587314168485-3236d6710814?w=400',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: '18',
      name: 'Pancake',
      description: 'Pancake dengan sirup maple dan mentega',
      price: 20000,
      category: 'Dessert',
      stock: 20,
      imageUrl:
          'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: '19',
      name: 'Kue Brownies',
      description: 'Brownies coklat lembut dengan kacang',
      price: 18000,
      category: 'Dessert',
      stock: 28,
      imageUrl:
          'https://images.unsplash.com/photo-1607920591413-4ec007e70023?w=400',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: '20',
      name: 'Es Campur',
      description: 'Es campur dengan buah-buahan segar',
      price: 14000,
      category: 'Dessert',
      stock: 35,
      imageUrl:
          'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  /// Get categories dari mock products
  static List<String> get categories {
    return mockProducts.map((product) => product.category).toSet().toList()
      ..sort();
  }

  /// Get products by category
  static List<Product> getProductsByCategory(String category) {
    if (category == 'Semua') return mockProducts;
    return mockProducts.where((p) => p.category == category).toList();
  }

  /// Search products by name
  static List<Product> searchProducts(String query) {
    if (query.isEmpty) return mockProducts;
    return mockProducts
        .where(
          (p) =>
              p.name.toLowerCase().contains(query.toLowerCase()) ||
              p.description.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  /// Get product by ID
  static Product? getProductById(String id) {
    try {
      return mockProducts.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}
