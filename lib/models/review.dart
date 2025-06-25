class PorterReview {
  final int rating;
  final String review;
  final String customerName;
  final String createdAt;

  PorterReview({
    required this.rating,
    required this.review,
    required this.customerName,
    required this.createdAt,
  });

  factory PorterReview.fromJson(Map<String, dynamic> json) {
    return PorterReview(
      rating: json['rating'] ?? 0,
      review: json['review'] ?? '',
      customerName: json['customer_name'] ?? '-',
      createdAt: json['created_at'] ?? '',
    );
  }
}
