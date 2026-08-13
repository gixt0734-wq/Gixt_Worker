import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  // Variables de almacenamiento
  static const String _tokenKey = 'token';
  static const String _refreshtokenKey = 'refreshtoken';
  static const String _inicioKey = 'inicio';
  static const String _idKey = 'id';
  static const String _imgKey = 'img';
  static const String _userKey = 'user';
  static const String _isworking = 'isworking';

  // Cargar los valores desde SharedPreferences
  Future<Map<String, dynamic>> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(_tokenKey);
    String? refreshtoken = prefs.getString(_refreshtokenKey);
    String? img = prefs.getString(_imgKey);
    String? user = prefs.getString(_userKey);
    bool? inicio = prefs.getBool(_inicioKey);
    String? id = prefs.getString(_idKey);
    bool? isworking = prefs.getBool(_isworking);
    return {
      'token': token,
      'refreshtoken': refreshtoken,
      'inicio': inicio,
      'id': id,
      'img': img,
      'user': user,
      'isworking': isworking,
    };
  }

  // Guardar los valores en SharedPreferences
  Future<void> savePreferences(String token, String refreshtoken, String inicio, String id ,String img, String user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_refreshtokenKey, refreshtoken);
    await prefs.setString(_inicioKey, inicio);
    await prefs.setString(_idKey, id);
    await prefs.setString(_userKey, user);
    await prefs.setString(_imgKey, img);
  }

  Future<void> savePreferencesUser(String img, String user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, user);
    await prefs.setString(_imgKey, img);
  }

  Future<void> savePreferencesToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.setString(_tokenKey, token);
  }

  Future<void> savePreferencesWorking(bool isworking) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isworking, isworking);
  }

  Future<void> clearPreferencesWorking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isworking);
  }

  // Eliminar todos los datos de SharedPreferences (opcional)
  Future<void> clearPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_inicioKey);
    await prefs.remove(_refreshtokenKey);
    await prefs.remove(_idKey);
    await prefs.remove(_imgKey);
    await prefs.remove(_userKey);
    await prefs.remove(_isworking);
  }

  Future<void> clearPreferencesUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_imgKey);
    await prefs.remove(_userKey);
  }
}
