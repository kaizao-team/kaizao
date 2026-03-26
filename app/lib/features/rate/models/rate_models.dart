class RatingDimension {
  final String name;
  final double rating;

  const RatingDimension({required this.name, this.rating = 0});

  RatingDimension copyWith({double? rating}) {
    return RatingDimension(name: name, rating: rating ?? this.rating);
  }

  factory RatingDimension.fromJson(Map<String, dynamic> json) {
    return RatingDimension(
      name: json['name'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'rating': rating};
}

class ReviewerInfo {
  final String id;
  final String nickname;
  final String? avatar;
  final String role;

  const ReviewerInfo({
    required this.id,
    required this.nickname,
    this.avatar,
    this.role = '',
  });

  factory ReviewerInfo.fromJson(Map<String, dynamic> json) {
    return ReviewerInfo(
      id: json['id'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatar: json['avatar'] as String?,
      role: json['role'] as String? ?? '',
    );
  }
}

class ReviewItem {
  final String id;
  final ReviewerInfo reviewer;
  final ReviewerInfo reviewee;
  final double overallRating;
  final List<RatingDimension> dimensions;
  final String comment;
  final String createdAt;

  const ReviewItem({
    required this.id,
    required this.reviewer,
    required this.reviewee,
    this.overallRating = 0,
    this.dimensions = const [],
    this.comment = '',
    this.createdAt = '',
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      id: json['id'] as String? ?? '',
      reviewer: ReviewerInfo.fromJson(
          json['reviewer'] as Map<String, dynamic>? ?? {}),
      reviewee: ReviewerInfo.fromJson(
          json['reviewee'] as Map<String, dynamic>? ?? {}),
      overallRating: (json['overall_rating'] as num?)?.toDouble() ?? 0,
      dimensions: (json['dimensions'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => RatingDimension.fromJson(e))
              .toList() ??
          [],
      comment: json['comment'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class ReviewSubmission {
  final String projectId;
  final String revieweeId;
  final double overallRating;
  final List<RatingDimension> dimensions;
  final String comment;

  const ReviewSubmission({
    required this.projectId,
    required this.revieweeId,
    required this.overallRating,
    required this.dimensions,
    required this.comment,
  });

  Map<String, dynamic> toJson() => {
        'project_id': projectId,
        'reviewee_id': revieweeId,
        'overall_rating': overallRating,
        'dimensions': dimensions.map((d) => d.toJson()).toList(),
        'comment': comment,
      };
}
