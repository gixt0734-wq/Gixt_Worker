import 'package:flutter/material.dart';


class HomeNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}

final homeNotifier = HomeNotifier();
