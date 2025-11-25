class UserModel {
  final String id;
  final String username;
  final String kemitraan;
  final String outlet;
  final String? subBrand;
  final String? profilePhotoUrl;
  final String? profilePhotoData;
  final String? role;

  UserModel({
    required this.id,
    required this.username,
    required this.kemitraan,
    required this.outlet,
    this.subBrand,
    this.profilePhotoUrl,
    this.profilePhotoData,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      kemitraan: json['kemitraan']?.toString() ?? '',
      outlet: json['outlet']?.toString() ?? '',
      subBrand: json['subBrand']?.toString(),
      profilePhotoUrl: json['profilePhotoUrl']?.toString(),
      profilePhotoData: json['profilePhotoData']?.toString(),
      role: json['role']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'kemitraan': kemitraan,
      'outlet': outlet,
      'subBrand': subBrand,
      'profilePhotoUrl': profilePhotoUrl,
      'profilePhotoData': profilePhotoData,
      'role': role,
    };
  }

  bool get hasSubBrand =>
      subBrand != null &&
      subBrand!.isNotEmpty &&
      kemitraan.toLowerCase().contains('nusantara');
}
