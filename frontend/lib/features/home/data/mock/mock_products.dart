import 'package:sagawa_pos_new/core/constants/app_constants.dart';
import 'package:sagawa_pos_new/features/home/domain/models/product.dart';
import 'package:sagawa_pos_new/core/network/api_client.dart';
import 'package:sagawa_pos_new/core/network/api_config.dart';
import 'package:sagawa_pos_new/data/services/user_service.dart';
import 'package:sagawa_pos_new/features/profile/domain/models/user_model.dart';

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

// Fetch menu items from backend API and map to local Product model
Future<List<Product>> fetchMenuProducts() async {
  final api = ApiClient();
  try {
    final response = await api.get(ApiConfig.menu);
    final data = response.data;
    // Get current logged-in user to filter menu by partnership/subBrand
    final UserModel? user = await UserService.getUser();

    // helper to check whether an item matches the user's partnership
    String _normalize(String s) {
      return s.toLowerCase().replaceAll(RegExp(r"[^a-z0-9]+"), "").trim();
    }

    bool matchesPartnership(dynamic item) {
      if (user == null) return true; // no user -> don't filter

      String itemKemitraan = '';
      String itemSubBrand = '';

      if (item is Map) {
        itemKemitraan = (item['kemitraan'] ?? item['partnership'] ?? '')
            .toString();
        itemSubBrand =
            (item['subBrand'] ?? item['sub_brand'] ?? item['subbrand'] ?? '')
                .toString();
      }

      final userKem = user.kemitraan.toString();

      // If user has subBrand (RM Nusantara case) -> show ONLY items that have matching subBrand
      if (user.hasSubBrand) {
        if (itemSubBrand.isEmpty) return false;
        return _normalize(itemSubBrand) == _normalize(user.subBrand ?? '');
      }

      // For other partnerships: require kemitraan to be present and match tolerantly
      if (itemKemitraan.isEmpty) return false;

      final nItem = _normalize(itemKemitraan);
      final nUser = _normalize(userKem);
      Map<String, dynamic>? q;
      if (user != null) {
        if (user.hasSubBrand) {
          q = {'subBrand': user.subBrand};
        } else if (user.kemitraan.isNotEmpty) {
          q = {'kemitraan': user.kemitraan};
        }
      }

      // match either direction (user contains item or item contains user) after normalization
      return nItem.contains(nUser) || nUser.contains(nItem);
    }

    // normalize to list of items whether API returns array or envelope
    List items = [];
    if (data is List) {
      items = data;
    } else if (data is Map && data['data'] is List) {
      items = data['data'] as List;
    }

    print(
      'DEBUG fetchMenuProducts - user kemitraan=${user?.kemitraan} subBrand=${user?.subBrand}',
    );
    try {
      for (final it in items) {
        if (it is Map) {
          final mid = (it['_id'] ?? it['id'])?.toString() ?? '';
          final mk = (it['kemitraan'] ?? it['partnership'] ?? '').toString();
          final ms = (it['subBrand'] ?? it['sub_brand'] ?? it['subbrand'] ?? '')
              .toString();
          final ok = matchesPartnership(it);
          // ignore: avoid_print
          print('DEBUG menu id=$mid kemitraan=$mk subBrand=$ms matches=$ok');
        }
      }
    } catch (e) {
      // ignore
    }

    // Filter items using partnership rules
    final filtered = items.where((e) => matchesPartnership(e)).toList();

    // Map filtered items into Product model
    return filtered.map<Product>((e) {
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
  } catch (e) {
    // Log and fallback
    // ignore: avoid_print
    print('Failed to fetch menu products: $e');
  }

  return fallbackMockProducts;
}
