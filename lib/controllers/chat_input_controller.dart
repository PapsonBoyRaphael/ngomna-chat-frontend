import 'package:flutter/material.dart';

class ChatInputStateController extends ChangeNotifier {
  bool _showAttachMenu = false;

  bool get showAttachMenu => _showAttachMenu;

  void toggleAttachMenu() {
    _showAttachMenu = !_showAttachMenu;
    notifyListeners();
  }

  void closeAttachMenu() {
    print(
        'ChatInputStateController: closeAttachMenu called. Current _showAttachMenu = $_showAttachMenu');
    if (_showAttachMenu) {
      _showAttachMenu = false;
      print('ChatInputStateController: closeAttachMenu executed');
      notifyListeners();
    }
  }
}
