// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';

// Project imports:
import 'package:torn_pda/models/profile/shortcuts_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class ShortcutsPage extends StatefulWidget {
  @override
  _ShortcutsPageState createState() => _ShortcutsPageState();
}

class _ShortcutsPageState extends State<ShortcutsPage> {
  SettingsProvider _settingsProvider;
  ShortcutsProvider _shortcutsProvider;
  ThemeProvider _themeProvider;

  final _customNameController = new TextEditingController();
  final _customURLController = new TextEditingController();
  var _customNameKey = GlobalKey<FormState>();
  var _customURLKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    routeWithDrawer = false;
    routeName = "shortcuts";
    _settingsProvider.willPopShouldGoBack.stream.listen((event) {
      if (mounted && routeName == "shortcuts") _goBack();
    });
  }

  @override
  Widget build(BuildContext context) {
    _shortcutsProvider = Provider.of<ShortcutsProvider>(context, listen: true);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? MediaQuery.of(context).orientation == Orientation.portrait
              ? Colors.blueGrey
              : _themeProvider.canvas
          : _themeProvider.canvas,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: _themeProvider.canvas,
          appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
          bottomNavigationBar: !_settingsProvider.appBarTop
              ? SizedBox(
                  height: AppBar().preferredSize.height,
                  child: buildAppBar(),
                )
              : null,
          body: Container(
            color: _themeProvider.canvas,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: 20),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text("ACTIVE SHORTCUTS"),
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Text(
                                    'SWIPE RIGHT TO REMOVE, LEFT TO EDIT',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Text(
                                    'LONG-PRESS TO SORT',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  if (_shortcutsProvider.activeShortcuts.length == 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(40, 10, 0, 10),
                      child: Text(
                        'No active shortcuts, add some below!',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    _activeCardsList(),
                  SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text("ALL SHORTCUTS"),
                  ),
                  SizedBox(height: 10),
                  _customCard(),
                  _allCardsList(),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Padding _activeCardsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Consumer<ShortcutsProvider>(
        builder: (context, shortcutProvider, child) {
          var activeShortcuts = <Widget>[];
          for (var short in shortcutProvider.activeShortcuts) {
            activeShortcuts.add(
              Scrollable(
                key: UniqueKey(),
                viewportBuilder: (BuildContext context, ViewportOffset position) => Slidable(
                  startActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    extentRatio: 0.25,
                    children: [
                      SlidableAction(
                        backgroundColor: Colors.red,
                        icon: Icons.remove_circle_outline_outlined,
                        onPressed: (context) {
                          _shortcutsProvider.deactivateShortcut(short);
                        },
                      ),
                    ],
                  ),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    extentRatio: 0.25,
                    children: [
                      SlidableAction(
                        backgroundColor: Colors.blue,
                        icon: Icons.edit,
                        onPressed: (context) {
                          _customNameController.text = short.nickname;
                          _customURLController.text = short.url;
                          _openEditDialog(short);
                        },
                      ),
                    ],
                  ),
                  child: Container(
                    height: 50,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: short.color, width: 1.5),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(2),
                              child: Image.asset(
                                short.iconUrl,
                                width: 18,
                                height: 18,
                                color: _themeProvider.mainText,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Flexible(child: Text(short.name)),
                                  Icon(Icons.reorder),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return Container(
            child: ReorderableListView(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              onReorder: (int oldIndex, int newIndex) {
                if (oldIndex < newIndex) {
                  // removing the item at oldIndex will shorten the list by 1
                  newIndex -= 1;
                }
                _shortcutsProvider.reorderShortcut(
                  _shortcutsProvider.activeShortcuts[oldIndex],
                  oldIndex,
                  newIndex,
                );
              },
              children: activeShortcuts,
            ),
          );
        },
      ),
    );
  }

  Padding _customCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        height: 50,
        child: Card(
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.orange[500], width: 1.5),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.all(2),
                  child: Image.asset(
                    "images/icons/pda_icon.png",
                    width: 18,
                    height: 18,
                    color: _themeProvider.mainText,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text('Custom shortcut')),
                      TextButton(
                        onPressed: () {
                          _openCustomDialog();
                        },
                        child: Text(
                          'ADD',
                          style: TextStyle(color: Colors.green[500]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Padding _allCardsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Consumer<ShortcutsProvider>(
        builder: (context, shortcutProvider, child) {
          var allShortcuts = <Widget>[];
          for (var short in shortcutProvider.allShortcuts) {
            allShortcuts.add(
              // Don't show those that are active
              !short.active
                  ? AnimatedOpacity(
                      opacity: short.visible ? 1 : 0,
                      duration: Duration(milliseconds: 300),
                      child: Container(
                        height: 50,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: short.color, width: 1.5),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Image.asset(
                                    short.iconUrl,
                                    width: 18,
                                    height: 18,
                                    color: _themeProvider.mainText,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(child: Text(short.name)),
                                      TextButton(
                                        onPressed: !short.visible
                                            // Avoid double press
                                            ? null
                                            : () async {
                                                // Start animation
                                                setState(() {
                                                  short.visible = false;
                                                });

                                                await Future.delayed(Duration(milliseconds: 300));

                                                setState(() {
                                                  shortcutProvider.activateShortcut(short);
                                                });

                                                // Reset visibility after animation
                                                short.visible = true;
                                              },
                                        child: Text(
                                          'ADD',
                                          style: TextStyle(color: Colors.green[500]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : SizedBox(),
            );
          }
          return ListView(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: allShortcuts,
          );
        },
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: Text("Shortcuts"),
      leading: new IconButton(
        icon: new Icon(Icons.arrow_back),
        onPressed: () {
          _goBack();
        },
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(
            Icons.delete,
            color: _themeProvider.buttonText,
          ),
          onPressed: () async {
            if (_shortcutsProvider.activeShortcuts.length == 0) {
              BotToast.showText(
                text: 'You have no active shortcuts, activate some!',
                textStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: Colors.orange[800],
                duration: Duration(seconds: 2),
                contentPadding: EdgeInsets.all(10),
              );
            } else {
              _openWipeDialog();
            }
          },
        ),
      ],
    );
  }

  Future<void> _openWipeDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          content: SingleChildScrollView(
            child: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.only(
                      top: 45,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    margin: EdgeInsets.only(top: 15),
                    decoration: new BoxDecoration(
                      color: _themeProvider.secondBackground,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: const Offset(0.0, 10.0),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // To make the card compact
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            "This will reset all your active shortcuts and order, "
                            "are you sure?",
                            style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: Text("Reset!"),
                              onPressed: () {
                                _shortcutsProvider.wipeAllShortcuts();
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: Text("Oh no!"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: _themeProvider.secondBackground,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.secondBackground,
                      radius: 22,
                      child: SizedBox(
                        height: 34,
                        width: 34,
                        child: Icon(Icons.delete_forever_outlined),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCustomDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          content: SingleChildScrollView(
            child: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.only(
                      top: 45,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    margin: EdgeInsets.only(top: 15),
                    decoration: new BoxDecoration(
                      color: _themeProvider.secondBackground,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: const Offset(0.0, 10.0),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // To make the card compact
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            "Add a name and URL for your custom shortcut. Note: "
                            "ensure URL begins with 'https://'",
                            style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        SizedBox(height: 15),
                        Form(
                          key: _customNameKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min, // To make the card compact
                            children: <Widget>[
                              TextFormField(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _themeProvider.mainText,
                                ),
                                textCapitalization: TextCapitalization.sentences,
                                controller: _customNameController,
                                maxLength: 30,
                                maxLines: 1,
                                decoration: InputDecoration(
                                  counterText: "",
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  labelText: 'Name',
                                ),
                                validator: (value) {
                                  if (value.replaceAll(' ', '').isEmpty) {
                                    return "Cannot be empty!";
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 15),
                        Row(
                          children: [
                            Flexible(
                              child: Form(
                                key: _customURLKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min, // To make the card compact
                                  children: <Widget>[
                                    TextFormField(
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _themeProvider.mainText,
                                      ),
                                      controller: _customURLController,
                                      maxLength: 300,
                                      maxLines: 1,
                                      decoration: InputDecoration(
                                        counterText: "",
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                        labelText: 'URL',
                                      ),
                                      validator: (value) {
                                        if (value.replaceAll(' ', '').isEmpty) {
                                          return "Cannot be empty!";
                                        }
                                        if (!value.toLowerCase().contains('https://')) {
                                          if (value.toLowerCase().contains('http://')) {
                                            return "Invalid, HTTPS needed!";
                                          }
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.paste),
                              onPressed: () async {
                                ClipboardData data = await Clipboard.getData('text/plain');
                                _customURLController.text = data.text;
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Flexible(
                          child: Text(
                            "Tip: long-press the app bar in the browser to copy the "
                            "current URL you are visiting. Then paste it here.",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: Text("Add"),
                              onPressed: () {
                                if (!_customNameKey.currentState.validate()) {
                                  return;
                                }
                                if (!_customURLKey.currentState.validate()) {
                                  return;
                                }

                                var customShortcut = Shortcut()
                                  ..name = _customNameController.text
                                  ..nickname = _customNameController.text
                                  ..url = _customURLController.text
                                  ..iconUrl = 'images/icons/pda_icon.png'
                                  ..color = Colors.orange[500]
                                  ..isCustom = true;

                                _shortcutsProvider.activateShortcut(customShortcut);
                                Navigator.of(context).pop();
                                _customNameController.text = '';
                                _customURLController.text = '';
                              },
                            ),
                            TextButton(
                              child: Text("Close"),
                              onPressed: () {
                                Navigator.of(context).pop();
                                _customNameController.text = '';
                                _customURLController.text = '';
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: _themeProvider.secondBackground,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.secondBackground,
                      radius: 22,
                      child: SizedBox(
                        height: 25,
                        width: 25,
                        child: Image.asset(
                          "images/icons/pda_icon.png",
                          width: 18,
                          height: 18,
                          color: _themeProvider.mainText,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openEditDialog(Shortcut shortcut) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          content: SingleChildScrollView(
            child: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.only(
                      top: 45,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    margin: EdgeInsets.only(top: 15),
                    decoration: new BoxDecoration(
                      color: _themeProvider.secondBackground,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: const Offset(0.0, 10.0),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // To make the card compact
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            "Add a name and URL for your custom shortcut. Note: "
                            "ensure URL begins with 'https://'",
                            style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        SizedBox(height: 15),
                        Form(
                          key: _customNameKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min, // To make the card compact
                            children: <Widget>[
                              TextFormField(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _themeProvider.mainText,
                                ),
                                textCapitalization: TextCapitalization.sentences,
                                controller: _customNameController,
                                maxLength: 20,
                                maxLines: 1,
                                decoration: InputDecoration(
                                  counterText: "",
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  labelText: 'Name',
                                ),
                                validator: (value) {
                                  if (value.replaceAll(' ', '').isEmpty) {
                                    return "Cannot be empty!";
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 15),
                        Row(
                          children: [
                            Flexible(
                              child: Form(
                                key: _customURLKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min, // To make the card compact
                                  children: <Widget>[
                                    TextFormField(
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _themeProvider.mainText,
                                      ),
                                      controller: _customURLController,
                                      maxLength: 300,
                                      maxLines: 1,
                                      decoration: InputDecoration(
                                        counterText: "",
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                        labelText: 'URL',
                                      ),
                                      validator: (value) {
                                        if (value.replaceAll(' ', '').isEmpty) {
                                          return "Cannot be empty!";
                                        }
                                        if (!value.toLowerCase().contains('https://')) {
                                          if (value.toLowerCase().contains('http://')) {
                                            return "Invalid, HTTPS needed!";
                                          }
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.paste),
                              onPressed: () async {
                                ClipboardData data = await Clipboard.getData('text/plain');
                                _customURLController.text = data.text;
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Flexible(
                          child: Text(
                            "Tip: long-press the app bar in the browser to copy the "
                            "current URL you are visiting. Then paste it here.",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: Text("Save"),
                              onPressed: () {
                                if (!_customNameKey.currentState.validate()) {
                                  return;
                                }
                                if (!_customURLKey.currentState.validate()) {
                                  return;
                                }

                                shortcut.name = _customNameController.text;
                                shortcut.nickname = _customNameController.text;
                                shortcut.url = _customURLController.text;
                                _shortcutsProvider.editShortcut(shortcut);

                                Navigator.of(context).pop();
                                _customNameController.text = '';
                                _customURLController.text = '';
                              },
                            ),
                            TextButton(
                              child: Text("Close"),
                              onPressed: () {
                                Navigator.of(context).pop();
                                _customNameController.text = '';
                                _customURLController.text = '';
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: _themeProvider.secondBackground,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.secondBackground,
                      radius: 22,
                      child: SizedBox(
                        height: 25,
                        width: 25,
                        child: Image.asset(
                          "images/icons/pda_icon.png",
                          width: 18,
                          height: 18,
                          color: _themeProvider.mainText,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _goBack() {
    routeWithDrawer = true;
    routeName = "settings";
    Navigator.of(context).pop();
  }
}
