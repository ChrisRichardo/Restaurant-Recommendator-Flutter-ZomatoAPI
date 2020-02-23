class Restaurant {
  final String id;
  final String name;
  final String url;
  final String currency;
  final String thumbUrl;
  final String imageUrl;
  final String cuisines;
  final String address;
  final Rating rating;
  final int priceRange;

  Restaurant.fromJson(json)
      : id = json['id'],
        name = json['name'],
        url = json['url'],
        currency = json['currency'],
        thumbUrl = json['thumb'],
        imageUrl = json['featured_image'],
        cuisines = json['cuisines'],
        address = json['location']['address'],
        rating = Rating.fromJson(json['user_rating']),
        priceRange = json['price_range'];

  String get priceDisplay {
    final buffer = StringBuffer();
    for (int i = 0; i < priceRange; i++) {
      buffer.write(currency);
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Restaurant && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Rating {
  final String text;
  final String average;

  Rating.fromJson(Map json)
      : text = json['rating_text'].toString(),
        average = json['aggregate_rating'].toString();
}