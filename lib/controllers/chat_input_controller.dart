import 'package:flutter/material.dart';

class ChatInputStateController extends ChangeNotifier {
  bool _showAttachMenu = false;

  bool get showAttachMenu => _showAttachMenu;

  void toggleAttachMenu() {
    _showAttachMenu = !_showAttachMenu;
    notifyListeners();
  }

  void closeAttachMenu() {
    if (_showAttachMenu) {
      _showAttachMenu = false;
      notifyListeners();
    }
  }
}
