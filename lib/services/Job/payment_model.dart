String formatType(String? type) {

    switch (type) {
      case 'diagnostic':
        return 'Diagnóstico y visita';
      case 'labor':
        return 'Mano de obra';
      case 'additional_works':
        return 'Extra';
      default:
        return '';
    }

}


class PaymentModel {
  // IDs
  String concept_type;
  double total;
  double cost;
  double iva;

  PaymentModel({
    required this.concept_type,
    required this.total,
    required this.iva,
    required this.cost,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {

    return PaymentModel(
      concept_type: formatType(json['concept_type'] ?? ''),
      total: json['total'] ?? '',
      iva :json['iva'] ?? '',
      cost: json['cost'] ?? '',
    );
  }
}
