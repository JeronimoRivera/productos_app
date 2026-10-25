class Product {
  final int id;
  final String name;
  final String category;
  final double price;
  final String image;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.image,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['title'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      image: json['thumbnail'] as String,
    );
  }
}
