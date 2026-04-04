class MaterialModel {
  String name;
  double cost;

  MaterialModel({required this.name, required this.cost});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'cost': cost,
    };
  }
}