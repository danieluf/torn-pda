import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:torn_pda/models/profile/shortcuts_model.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class ShortcutsProvider extends ChangeNotifier {
  List<Shortcut> _allShortcuts = [];
  UnmodifiableListView<Shortcut> get allShortcuts =>
      UnmodifiableListView(_allShortcuts);

  List<Shortcut> _activeShortcuts = [];
  UnmodifiableListView<Shortcut> get activeShortcuts =>
      UnmodifiableListView(_activeShortcuts);

  String _currentFilter = '';
  String get currentFilter => _currentFilter;

  ShortcutsProvider() {
    _allShortcuts = _initializeShortcuts();
    _loadSavedShortcuts();
  }

  void activateShortcut(Shortcut activeShortcut) {
    activeShortcut.active = true;
    _activeShortcuts.add(activeShortcut);
    _saveListAfterChanges();
    notifyListeners();
  }

  void deactivateShortcut(Shortcut inactiveShortcut) {
    inactiveShortcut.active = false;
    _activeShortcuts.remove(inactiveShortcut);
    _saveListAfterChanges();
    notifyListeners();
  }

  void reorderShortcut(Shortcut movedShortcut, int oldIndex, int newIndex) {
    _activeShortcuts.removeAt(oldIndex);
    _activeShortcuts.insert(newIndex, movedShortcut);
    _saveListAfterChanges();
    notifyListeners();
  }

  void _saveListAfterChanges() {
    var saveList = List<String>();
    for (var short in activeShortcuts) {
      var save = shortcutToJson(short);
      saveList.add(save);
    }
    SharedPreferencesModel().setActiveShortcutsList(saveList);
  }

  Future<void> _loadSavedShortcuts() async {
    // Load crimes from shared preferences
    var rawLoad = await SharedPreferencesModel().getActiveShortcutsList();
    for (var rawShort in rawLoad) {
      _activeShortcuts.add(shortcutFromJson(rawShort));
    }
    notifyListeners();
  }

  List<Shortcut> _initializeShortcuts() {
    var stockShortcuts = List<Shortcut>();
    stockShortcuts.addAll({
      Shortcut()
        ..name = "Casino: Russian Roulette"
        ..nickname = "Russian Roulette"
        ..url = "https://www.torn.com/page.php?sid=russianRoulette#"
        ..iconUrl = "images/icons/faction.png",
      Shortcut()
        ..name = "shortcut 2"
        ..url = "url 2"
        ..iconUrl = "images/flags/stock/china.png",
    });
    return stockShortcuts;
  }

}
