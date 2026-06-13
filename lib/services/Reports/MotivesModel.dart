class MotiveModel {
  String motive;
  String description;
  MotiveModel({required this.motive, required this.description});
}

enum ReportType { clientToWorker, workerToUser, jobDispute }

class ReportMotivesService {
  static final Map<ReportType, List<MotiveModel>> _motives = {
    ReportType.clientToWorker: [
      MotiveModel(motive: 'Abuso o acoso', description: 'El trabajador está siendo ofensivo, amenazante o acosador.'),
      MotiveModel(motive: 'No se presentó', description: 'El trabajador aceptó el trabajo pero nunca llegó.'),
      MotiveModel(motive: 'Trabajo incompleto', description: 'El trabajador no terminó el servicio acordado.'),
      MotiveModel(motive: 'Cobro indebido', description: 'Se cobró un monto diferente al acordado o sin justificación.'),
      MotiveModel(motive: 'Daños a la propiedad', description: 'El trabajador causó daños durante la prestación del servicio.'),
      MotiveModel(motive: 'Suplantación de identidad', description: 'La persona que llegó no es el trabajador registrado.'),
      MotiveModel(motive: 'Comportamiento inapropiado', description: 'Conducta fuera de lugar o que incomoda al cliente.'),
      MotiveModel(motive: 'Otro', description: 'Cualquier otro motivo que no esté en la lista anterior.'),
    ],
    ReportType.workerToUser: [
      MotiveModel(motive: 'Abuso o agresión', description: 'El usuario fue ofensivo, agresivo o amenazante.'),
      MotiveModel(motive: 'Información falsa', description: 'Los detalles del trabajo no coincidían con la realidad.'),
      MotiveModel(motive: 'Cancelación injustificada', description: 'El usuario canceló sin previo aviso estando el trabajador en camino.'),
      MotiveModel(motive: 'Negativa de pago', description: 'El usuario se negó a pagar el monto acordado.'),
      MotiveModel(motive: 'Solicitud fuera del servicio', description: 'El usuario exigió tareas no incluidas en el acuerdo.'),
      MotiveModel(motive: 'Suplantación de identidad', description: 'La persona en el lugar no es el usuario que contrató.'),
      MotiveModel(motive: 'Comportamiento inapropiado', description: 'Conducta que incomoda o pone en riesgo al trabajador.'),
      MotiveModel(motive: 'Otro', description: 'Cualquier otro motivo que no esté en la lista anterior.'),
    ],
    ReportType.jobDispute: [
      MotiveModel(motive: 'Pago no recibido', description: 'El trabajo se completó pero el pago no fue procesado.'),
      MotiveModel(motive: 'Monto incorrecto', description: 'Se cobró o transfirió un monto diferente al acordado.'),
      MotiveModel(motive: 'Reembolso no aplicado', description: 'Se acordó un reembolso parcial o total que no se reflejó.'),
      MotiveModel(motive: 'Materiales no reconocidos', description: 'Se cobraron materiales que el usuario no autorizó.'),
      MotiveModel(motive: 'Trabajo no iniciado', description: 'Se realizó el cobro pero el trabajo nunca comenzó.'),
      MotiveModel(motive: 'Disputa por calidad', description: 'El trabajo no cumplió con lo acordado y se solicita ajuste.'),
      MotiveModel(motive: 'Otro', description: 'Cualquier otro motivo relacionado con el pago o el trabajo.'),
    ],
  };

  /// Obtiene la lista de motivos según el tipo de reporte
  static List<MotiveModel> getMotives(ReportType type) {
    return _motives[type] ?? [];
  }

  /// Agrega un motivo personalizado a un tipo de reporte
  static void addMotive(ReportType type, MotiveModel motive) {
    _motives[type]?.add(motive);
  }

  /// Busca motivos por texto en motive o description
  static List<MotiveModel> search(ReportType type, String query) {
    final q = query.toLowerCase();
    return getMotives(type)
        .where((m) =>
            m.motive.toLowerCase().contains(q) ||
            m.description.toLowerCase().contains(q))
        .toList();
  }

  /// Obtiene un motivo por nombre exacto
  static MotiveModel? getByMotive(ReportType type, String motive) {
    final list = getMotives(type);
    try {
      return list.firstWhere((m) => m.motive == motive);
    } catch (_) {
      return null;
    }
  }
}