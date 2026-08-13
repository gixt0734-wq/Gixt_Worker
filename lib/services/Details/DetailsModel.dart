
class DetailsModel {
  String name;
  double value;

  DetailsModel({required this.name, required this.value});

  factory DetailsModel.fromJson(Map<String, dynamic> json) {
    return DetailsModel(
      name: json['field_name'] ?? '',
      value: (json['field_value'] ?? 0).toDouble(),
    );
  }
}