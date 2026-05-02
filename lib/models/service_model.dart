/// Representa un servicio veterinario activo (tabla `services`).
class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.name,
    this.description,
    required this.durationMinutes,
    required this.price,
  });

  final String id;
  final String name;
  final String? description;
  final int durationMinutes;
  final double price;

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Precio formateado sin decimales: "$50,000"
  String get priceFormatted =>
      '\$${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

  /// Duración formateada: "30 min"
  String get durationFormatted => '$durationMinutes min';
}
