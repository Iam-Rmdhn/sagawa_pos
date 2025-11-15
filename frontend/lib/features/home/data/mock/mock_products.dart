import 'package:sagawa_pos_new/core/constants/app_constants.dart';
import 'package:sagawa_pos_new/features/home/domain/models/product.dart';

/// Daftar produk mock (sementara) yang bisa diganti sumber API nanti.
const mockProducts = <Product>[
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
