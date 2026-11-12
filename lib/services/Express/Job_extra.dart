
class Job_extra {
  // IDs

  String problem;
  String description;
  String image_url;
  double labor_cost;

  Job_extra({
    required this.problem,
    required this.description,
    required this.image_url,
    required this.labor_cost,
  });

  factory Job_extra.fromJson(Map<String, dynamic> json) {
    return Job_extra(
      problem: json['problem'] ?? '',
      description :json['description'] ?? '',
      image_url: json['image_url'] ?? '',
      labor_cost: (json['labor_cost'] as num?)?.toDouble() ?? 0,
    );
  }
}
