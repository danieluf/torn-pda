// Flutter imports:
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/pages/chaining/attacks_page.dart';
//import 'package:torn_pda/pages/chaining/tac/tac_page.dart';
import 'package:torn_pda/pages/chaining/targets_page.dart';
import 'package:torn_pda/pages/chaining/war_page.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/animated_indexedstack.dart';
import 'package:torn_pda/widgets/bounce_tabbar.dart';

import '../main.dart';
//import 'package:torn_pda/utils/shared_prefs.dart';

class ChainingPage extends StatefulWidget {
  @override
  _ChainingPageState createState() => _ChainingPageState();
}

class _ChainingPageState extends State<ChainingPage> {
  ThemeProvider _themeProvider;
  ChainStatusProvider _chainStatusProvider;
  Future _preferencesLoaded;
  SettingsProvider _settingsProvider;

  int _currentPage = 0;
  bool _isAppBarTop;

  //bool _tacEnabled = true;

  @override
  void initState() {
    super.initState();
    _chainStatusProvider = Provider.of<ChainStatusProvider>(context, listen: false);
    _isAppBarTop = context.read<SettingsProvider>().appBarTop;
    _preferencesLoaded = _restorePreferences();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final bool isThemeLight = _themeProvider.currentTheme == AppTheme.light || false;
    final double padding = _isAppBarTop ? 0 : kBottomNavigationBarHeight;
    return Scaffold(
      backgroundColor: _themeProvider.basicBackground,
      extendBody: true,
      body: FutureBuilder(
        future: _preferencesLoaded,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: padding),
                  child: AnimatedIndexedStack(
                    index: _currentPage,
                    duration: 200,
                    children: <Widget>[
                      TargetsPage(
                          // Used to add or remove TAC tab
                          //tabCallback: _tabCallback,
                          ),
                      AttacksPage(),
                      WarPage(),
                      /*
                      TacPage(
                        userKey: _myCurrentKey,
                      ),
                      */
                    ],
                    errorCallback: null,
                  ),
                ),
                if (!_isAppBarTop)
                  FutureBuilder(
                    future: _preferencesLoaded,
                    builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return BounceTabBar(
                          onTabChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                            handleSectionChange(index);
                          },
                          themeProvider: _themeProvider,
                          items: [
                            Image.asset(
                              'images/icons/ic_target_account_black_48dp.png',
                              color: isThemeLight ? Colors.white : _themeProvider.mainText,
                              width: 28,
                            ),
                            Icon(
                              Icons.people,
                              color: isThemeLight ? Colors.white : _themeProvider.mainText,
                            ),
                            Icon(
                              MdiIcons.wall,
                              color: isThemeLight ? Colors.white : _themeProvider.mainText,
                            ),
                            // Text('TAC', style: TextStyle(color: _themeProvider.mainText))
                          ],
                          locationTop: true,
                        );
                      } else {
                        return SizedBox.shrink();
                      }
                    },
                  ),
              ],
            );
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
      bottomNavigationBar: _isAppBarTop
          ? FutureBuilder(
              future: _preferencesLoaded,
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return BounceTabBar(
                    initialIndex: _currentPage,
                    onTabChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                      handleSectionChange(index);
                    },
                    themeProvider: _themeProvider,
                    items: [
                      Image.asset(
                        'images/icons/ic_target_account_black_48dp.png',
                        color: isThemeLight ? Colors.white : _themeProvider.mainText,
                        width: 28,
                      ),
                      Icon(
                        Icons.people,
                        color: isThemeLight ? Colors.white : _themeProvider.mainText,
                      ),
                      Image.asset(
                        'images/icons/faction.png',
                        width: 17,
                        color: isThemeLight ? Colors.white : _themeProvider.mainText,
                      ),
                      // Text('TAC', style: TextStyle(color: _themeProvider.mainText))
                    ],
                    locationTop: false,
                  );
                } else {
                  return SizedBox.shrink();
                }
              },
            )
          : const SizedBox.shrink(),
    );
  }

  /*
  void _tabCallback(bool tacEnabled) {
    setState(() {
      _tacEnabled = tacEnabled;
    });
  }
  */

  Future _restorePreferences() async {
    //_tacEnabled = await Prefs().getTACEnabled();

    if (!_chainStatusProvider.initialised) {
      await _chainStatusProvider.loadPreferences();
    }

    _currentPage = await Prefs().getChainingCurrentPage();
    switch (_currentPage) {
      case 0:
        analytics.setCurrentScreen(screenName: 'targets');
        break;
      case 1:
        analytics.setCurrentScreen(screenName: 'attacks');
        break;
      case 2:
        analytics.setCurrentScreen(screenName: 'war');
        if (!_settingsProvider.showCases.contains("war")) {
          Get.put(WarController()).launchShowCaseAddFaction();
          _settingsProvider.addShowCase = "war";
        }
        break;
    }
  }

  // IndexedStack loads all sections at the same time, but we need to load certain things when we
  // enter the section
  void handleSectionChange(int index) {
    switch (index) {
      case 0:
        analytics.setCurrentScreen(screenName: 'targets');
        Prefs().setChainingCurrentPage(_currentPage);
        break;
      case 1:
        analytics.setCurrentScreen(screenName: 'attacks');
        Prefs().setChainingCurrentPage(_currentPage);
        break;
      case 2:
        analytics.setCurrentScreen(screenName: 'war');
        if (!_settingsProvider.showCases.contains("war")) {
          Get.put(WarController()).launchShowCaseAddFaction();
          _settingsProvider.addShowCase = "war";
        }
        Prefs().setChainingCurrentPage(_currentPage);
        break;
    }
  }
}
