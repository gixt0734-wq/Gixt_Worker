import 'package:flutter/material.dart';
import 'package:gixt_worker/Config/location.dart';

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

class CancelJobsNotifier extends ChangeNotifier {
  void refresh() async {
    print('canceladop');
    notifyListeners();
    await LocationService.stop();
  }
}

final jobsNotifier = JobsNotifier();
final canceljobNotifier = CancelJobsNotifier();
final jobsStatusNotifier = JobsStatusNotifier();
final jobsStatusNotifierFinish = JobsStatusNotifierFinish();