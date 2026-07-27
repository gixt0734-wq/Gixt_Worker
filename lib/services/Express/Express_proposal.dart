
class Express_proposal {
  // IDs

  String worker_image;
  String worker_id;
  String created_at;

  Express_proposal({
    required this.worker_image,
    required this.worker_id,
    required this.created_at,
  });

  factory Express_proposal.fromJson(Map<String, dynamic> json) {
    final worker = json['worker'] ?? {};
    return Express_proposal(
      worker_image: json['worker_id'] ?? '',
      worker_id :json['worker_id'] ?? '',
      created_at: json['created_at'] ?? '',
    );
  }
}
