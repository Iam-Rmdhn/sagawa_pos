import 'package:sagawa_pos_new/core/constants/app_constants.dart';
import 'package:sagawa_pos_new/features/home/domain/models/product.dart';
import 'package:sagawa_pos_new/core/network/api_client.dart';
import 'package:sagawa_pos_new/core/network/api_config.dart';

/// Fallback mock products (used when API fetch fails or offline)
const fallbackMockProducts = <Product>[
  Product(
    id: 'p1',
    title: 'Sate Ayam Original',
    price: 20000,
    imageAsset: AppImages.onboardingIllustration,
  ),
  Product(
    id: 'p2',
    title: 'Sate Ayam Pedas',
    price: 20000,
    imageAsset: AppImages.onboardingIllustration,
  ),
  Product(
    id: 'p3',
    title: 'Sate Kulit Crispy',
    price: 20000,
    imageAsset: AppImages.onboardingIllustration,
  ),
  Product(
    id: 'p4',
    title: 'Sate Mix Favorit',
    price: 20000,
    imageAsset: AppImages.onboardingIllustration,
  ),
  Product(
    id: 'p5',
    title: 'Sate Mozarella',
    price: 20000,
    imageAsset: AppImages.onboardingIllustration,
  ),
  Product(
    id: 'p6',
    title: 'Sate Manis',
    price: 20000,
    imageAsset: AppImages.onboardingIllustration,
  ),
];

/// Fetch menu items from backend API and map to local Product model
/// Returns fallbackMockProducts if fetch fails.
Future<List<Product>> fetchMenuProducts() async {
  final api = ApiClient();
  try {
    final response = await api.get(ApiConfig.menu);
    final data = response.data;

    // Backend returns a JSON array of menu items
    if (data is List) {
      return data.map<Product>((e) {
        final id = (e['_id'] ?? e['id'])?.toString() ?? '';
        final title = (e['name'] ?? e['title'] ?? '').toString();
        final dynamic priceRaw = e['price'];
        int price = 0;
        if (priceRaw != null) {
          if (priceRaw is int)
            price = priceRaw;
          else if (priceRaw is double)
            price = priceRaw.toInt();
          else
            price = int.tryParse(priceRaw.toString()) ?? 0;
        }

        // prefer imageData (base64 data:) over imageUrl when available
        final imageData = e['imageData'] ?? e['image_data'];
        String image;
        if (imageData != null && imageData.toString().isNotEmpty) {
          image = imageData.toString();
        } else {
          image =
              (e['imageUrl'] ??
                      e['image_url'] ??
                      AppImages.onboardingIllustration)
                  .toString();
        }

        return Product(id: id, title: title, price: price, imageAsset: image);
      }).toList();
    }

    // In case API wraps results in an envelope
    if (data is Map && data['data'] is List) {
      final list = data['data'] as List;
      return list.map<Product>((e) {
        final id = (e['_id'] ?? e['id'])?.toString() ?? '';
        final title = (e['name'] ?? e['title'] ?? '').toString();
        final dynamic priceRaw = e['price'];
        int price = 0;
        if (priceRaw != null) {
          if (priceRaw is int)
            price = priceRaw;
          else if (priceRaw is double)
            price = priceRaw.toInt();
          else
            price = int.tryParse(priceRaw.toString()) ?? 0;
        }
        final imageData = e['imageData'] ?? e['image_data'];
        String image;
        if (imageData != null && imageData.toString().isNotEmpty) {
          image = imageData.toString();
        } else {
          image =
              (e['imageUrl'] ??
                      e['image_url'] ??
                      AppImages.onboardingIllustration)
                  .toString();
        }

        return Product(id: id, title: title, price: price, imageAsset: image);
      }).toList();
    }
  } catch (e) {
    // Log and fallback
    // ignore: avoid_print
    print('Failed to fetch menu products: $e');
  }

  return fallbackMockProducts;
}
