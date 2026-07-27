import 'package:flutter/material.dart';


class CatalogNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}

final catalogNotifier = CatalogNotifier();
