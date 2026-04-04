import 'package:flutter/material.dart';

class JobsNotifier extends ChangeNotifier {
  String? _id;

  String? get id => _id;

  void refresh(String newId) {
    _id = newId;
    notifyListeners();
  }

  void clear() {
    _id = null;
  }
}

class JobsStatusNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();

  }
}
class JobsStatusNotifierFinish extends ChangeNotifier {
  void refresh() {
    notifyListeners();
    print('object');
  }
}

final jobsNotifier = JobsNotifier();
final jobsStatusNotifier = JobsStatusNotifier();
final jobsStatusNotifierFinish = JobsStatusNotifierFinish();