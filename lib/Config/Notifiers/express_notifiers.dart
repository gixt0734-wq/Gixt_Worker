import 'package:flutter/material.dart';

class ExpressNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}



class CancelExpressNotifier extends ChangeNotifier {
  void refresh() async {
    notifyListeners();
    //  await LocationService.stop();
  }
}

final expressNotifier = ExpressNotifier();
final cancelexpressNotifier = CancelExpressNotifier();