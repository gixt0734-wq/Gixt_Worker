import 'package:flutter/material.dart';
import 'package:gixt_worker/Config/location.dart';

class ExpressNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}

class CancelExpressNotifier extends ChangeNotifier {
  void refresh() async {
    print('canceladop');
    notifyListeners();
    await LocationService.stop();
  }
}

class FinishExpressNotifier extends ChangeNotifier {
  void refresh() async {
    print('canceladop');
    notifyListeners();
    await LocationService.stop();
  }
}

final expressNotifier = ExpressNotifier();
final cancelexpressNotifier = CancelExpressNotifier();
final finishexpressNotifier = FinishExpressNotifier();