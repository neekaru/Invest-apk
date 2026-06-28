import 'package:flutter/foundation.dart';

class RefreshBus extends ChangeNotifier {
  static final RefreshBus _instance = RefreshBus._();
  factory RefreshBus() => _instance;
  RefreshBus._();

  void notify() => notifyListeners();
}

final refreshBus = RefreshBus();
