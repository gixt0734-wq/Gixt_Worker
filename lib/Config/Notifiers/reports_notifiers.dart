import 'package:flutter/material.dart';


class ReportsNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}

final reportsNotifier = ReportsNotifier();
