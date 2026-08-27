class LocationCacheService {
  static final LocationCacheService _instance =
      LocationCacheService._internal();
  factory LocationCacheService() => _instance;
  LocationCacheService._internal();

  double? latitud;
  double? longitud;
  // String? ciudad;
  // String? calle;
  // String? estado;
  // String? colonia;
  // String? pais;

  bool get hasPosicion => latitud != null && longitud != null;

  void updatePosicion(double latitud, double longitud) {
    this.latitud = latitud;
    this.longitud = longitud;
  }

  // void updateDireccion({
  //   required String ciudad,
  //   String? calle,
  //   required String estado,
  //   required String colonia,
  //   required String pais,
  // }) {
  //   this.ciudad = ciudad;
  //   this.calle = calle;
  //   this.estado = estado;
  //   this.colonia = colonia;
  //   this.pais = pais;
  // }
}
