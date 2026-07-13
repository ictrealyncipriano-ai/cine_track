class RegistrationChart {
  final List<String> dates;
  final List<int> values;

  const RegistrationChart({required this.dates, required this.values});

  factory RegistrationChart.fromJson(Map<String, dynamic> json) {
    return RegistrationChart(
      dates: List<String>.from(json['dates'] ?? []),
      values: List<int>.from((json['values'] as List<dynamic>?)?.map((e) => (e as num).toInt()) ?? []),
    );
  }
}

class ReviewChart {
  final List<String> dates;
  final List<int> values;

  const ReviewChart({required this.dates, required this.values});

  factory ReviewChart.fromJson(Map<String, dynamic> json) {
    return ReviewChart(
      dates: List<String>.from(json['dates'] ?? []),
      values: List<int>.from((json['values'] as List<dynamic>?)?.map((e) => (e as num).toInt()) ?? []),
    );
  }
}

class Analytics {
  final RegistrationChart registrations;
  final ReviewChart reviewsPerDay;
  final Map<String, int> reviewStatuses;

  const Analytics({
    required this.registrations,
    required this.reviewsPerDay,
    required this.reviewStatuses,
  });

  factory Analytics.fromJson(Map<String, dynamic> json) {
    return Analytics(
      registrations: RegistrationChart.fromJson(json['registrations'] as Map<String, dynamic>? ?? {}),
      reviewsPerDay: ReviewChart.fromJson(json['reviews_per_day'] as Map<String, dynamic>? ?? {}),
      reviewStatuses: (json['review_statuses'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          {},
    );
  }
}
