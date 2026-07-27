
class Jobs_proposal {
  // IDs
  String job_id;
  String worker_image;
  String worker_id;
  String created_at;

  Jobs_proposal({
    required this.job_id,
    required this.worker_image,
    required this.worker_id,
    required this.created_at,
  });

  factory Jobs_proposal.fromJson(Map<String, dynamic> json) {
    final worker = json['worker'] ?? {};

    return Jobs_proposal(
      job_id: json['job_id'] ?? '',
      worker_image: json['image'] ?? '',
      worker_id :json['worker_id'] ?? '',
      created_at: json['created_at'] ?? '',
    );
  }
}
