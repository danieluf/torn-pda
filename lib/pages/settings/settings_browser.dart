// Dart imports:
import 'dart:async';
import 'dart:io';

// Flutter imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/main.dart';

// Project imports:
import 'package:torn_pda/pages/settings/friendly_factions.dart';
import 'package:torn_pda/pages/settings/userscripts_page.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/webviews/pda_browser_icon.dart';

class SettingsBrowserPage extends StatefulWidget {
  const SettingsBrowserPage({Key key}) : super(key: key);

  @override
  _SettingsBrowserPageState createState() => _SettingsBrowserPageState();
}

class _SettingsBrowserPageState extends State<SettingsBrowserPage> {
  Timer _ticker;

  Future _preferencesRestored;

  bool _highlightChat;
  Color _highlightColor = Color(0xff7ca900);

  int _browserStyle = 0;

  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;
  UserScriptsProvider _userScriptsProvider;
  WebViewProvider _webViewProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _userScriptsProvider = Provider.of<UserScriptsProvider>(context, listen: false);

    _preferencesRestored = _restorePreferences();

    routeWithDrawer = false;
    routeName = "settings_browser";
    _settingsProvider.willPopShouldGoBack.stream.listen((event) {
      if (mounted && routeName == "settings_browser") _goBack();
    });
  }

  @override
  Widget build(BuildContext context) {
    _webViewProvider = Provider.of<WebViewProvider>(context, listen: true);
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
            child: FutureBuilder(
              future: _preferencesRestored,
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
                    child: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          SizedBox(height: 15),
                          _general(),
                          SizedBox(height: 15),
                          Divider(),
                          SizedBox(height: 15),
                          _userScripts(),
                          SizedBox(height: 15),
                          Divider(),
                          SizedBox(height: 10),
                          _tabs(),
                          SizedBox(height: 15),
                          Divider(),
                          SizedBox(height: 10),
                          _fullScreen(),
                          SizedBox(height: 15),
                          Divider(),
                          SizedBox(height: 10),
                          _chat(context),
                          SizedBox(height: 15),
                          Divider(),
                          SizedBox(height: 10),
                          _travel(),
                          SizedBox(height: 15),
                          Divider(),
                          SizedBox(height: 10),
                          _gym(),
                          SizedBox(height: 15),
                          Divider(),
                          SizedBox(height: 10),
                          _profile(),
                          if (Platform.isIOS)
                            Column(
                              children: [
                                SizedBox(height: 15),
                                Divider(),
                                SizedBox(height: 10),
                                _linkPreview(),
                              ],
                            ),
                          if (Platform.isIOS)
                            Column(
                              children: [
                                SizedBox(height: 15),
                                Divider(),
                                SizedBox(height: 10),
                                _pinchGesture(),
                                _iosDisallowOverScroll(),
                              ],
                            ),
                          SizedBox(height: 15),
                          Divider(),
                          SizedBox(height: 10),
                          _maintenance(),
                          SizedBox(height: 40),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Column _profile() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'PLAYER PROFILES',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Extra player information"),
                  Switch(
                    value: _settingsProvider.extraPlayerInformation,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.changeExtraPlayerInformation = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Add additional player information when visiting a profile or attacking '
                'someone (e.g. same faction, friendly faction, friends) and estimated stats',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            if (_settingsProvider.extraPlayerInformation)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          "Show players' stats",
                        ),
                        _profileStatsDropdown(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            "If 'all stats' is selected, you will be shown either spied stats (supported by YATA and Torn Stats) or estimated stats "
                            "(which might be inaccurate) if the former can't be found. Alternatively, select only spied stats or hide all stats entirely.",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            if (_settingsProvider.extraPlayerInformation)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          "Friendly factions",
                        ),
                        IconButton(
                            icon: Icon(Icons.keyboard_arrow_right_outlined),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (BuildContext context) => FriendlyFactionsPage(),
                                ),
                              );
                            }),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'You will see a note if you are visiting the profile of a '
                      'friendly faction\'s player, or a warning if you are about to attack',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            if (_settingsProvider.extraPlayerInformation)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text("Show networth"),
                    Switch(
                      value: _settingsProvider.extraPlayerNetworth,
                      onChanged: (value) {
                        setState(() {
                          _settingsProvider.changeExtraPlayerNetworth = value;
                        });
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'If enabled, this will show an additional line with the networth of the '
                'player you are visiting',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Column _userScripts() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'USER SCRIPTS',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Enable custom user scripts"),
                  Switch(
                    value: _userScriptsProvider.userScriptsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _userScriptsProvider.setUserScriptsEnabled = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'You can load custom user scripts in the browser (this feature does not currently '
                'work when using the browser for chaining)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            if (_userScriptsProvider.userScriptsEnabled)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          "Manage scripts",
                        ),
                        IconButton(
                          icon: Icon(Icons.keyboard_arrow_right_outlined),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (BuildContext context) => UserScriptsPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Column _linkPreview() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'LINKS PREVIEW',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Allow links preview"),
                  Switch(
                    value: _settingsProvider.iosAllowLinkPreview,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.changeIosAllowLinkPreview = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Allow browser to open an iOS native preview windows when '
                'long-pressing a link (only iOS 9+)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Column _pinchGesture() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'GESTURES',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Zoom in/out pinch gestures"),
                  Switch(
                    value: _settingsProvider.iosBrowserPinch,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.setIosBrowserPinch = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Column _iosDisallowOverScroll() {
    return Column(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Disallow overscroll"),
                  Switch(
                    value: _settingsProvider.iosDisallowOverscroll,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.setIosDisallowOverscroll = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Certain iOS versions (e.g.: iOS 16) might have issues with Torn overs-scrolling horizontally. '
                'By using this option you might get rid of such behavior. NOTE: this will restrict pull-to-refresh '
                'to work only from swipes at the top part of the browser.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Column _maintenance() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MAINTENANCE',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Restore session cookie"),
                  Switch(
                    value: _settingsProvider.restoreSessionCookie,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.restoreSessionCookie = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Enable this option if you are getting logged out from Torn consistently; '
                'Torn PDA will try to reestablish your session ID when the browser opens',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Browser cache"),
                  ElevatedButton(
                    child: Text("Clear"),
                    onPressed: () async {
                      _webViewProvider.clearCacheAndTabs();

                      BotToast.showText(
                        text: "Browser cache and tabs have been reset!",
                        textStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        contentColor: Colors.grey[600],
                        duration: const Duration(seconds: 3),
                        contentPadding: const EdgeInsets.all(10),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Note: this will clear your browser\'s cache and current tabs. It can be '
                'useful in case of errors (sections not loading correctly, etc.). '
                'You\'ll be logged-out from Torn and all other sites',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Column _travel() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'TRAVEL',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Remove airplane"),
              Switch(
                value: _settingsProvider.removeAirplane,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeRemoveAirplane = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'Removes airplane and cloud animation when travelling',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Column _gym() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ENERGY',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Warn about chains"),
              Switch(
                value: _settingsProvider.warnAboutChains,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeWarnAboutChains = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            'If active, you\'ll get a message and a chain icon to the side of '
            'the energy bar, so that you avoid spending energy in the gym or hunting'
            'if you are unaware that your faction is chaining',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Warn about stacking"),
              Switch(
                value: _settingsProvider.warnAboutExcessEnergy,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeWarnAboutExcessEnergy = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            'If active, you\'ll get a message if your open a browser to the gym or go hunting'
            'and your energy is AT OR ABOVE your selected threshold, in case you forgot that '
            'you are stacking',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        if (_settingsProvider.warnAboutExcessEnergy)
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "Threshold",
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _settingsProvider.warnAboutExcessEnergyThreshold.toString(),
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        Slider(
                          min: 200,
                          max: 1000,
                          divisions: 16,
                          value: _settingsProvider.warnAboutExcessEnergyThreshold.toDouble(),
                          onChanged: (double value) {
                            setState(() {
                              _settingsProvider.changeWarnAboutExcessEnergyThreshold = value.floor();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Column _chat(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'CHAT',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Show chat remove icon"),
              Switch(
                value: _settingsProvider.chatRemoveEnabled,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeChatRemoveEnabled = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Highlight own name in chat"),
              Switch(
                value: _settingsProvider.highlightChat,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeHighlightChat = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        if (_highlightChat)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  _showColorPickerChat(context);
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 35, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text("Choose highlight colour"),
                      Container(
                        width: 25,
                        height: 25,
                        color: _highlightColor,
                      )
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'The sender\'s name will appear darker '
                  'to improve readability',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          )
        else
          SizedBox.shrink(),
      ],
    );
  }

  Column _general() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'GENERAL',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Browser style"),
              _browserStyleDropdown(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "There are three browser styles available, all sharing the same functionality. Please have a look "
            "at the Tips section for more information, or try them for yourself!",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Show load bar"),
              Switch(
                value: _settingsProvider.loadBarBrowser,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeLoadBarBrowser = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Refresh method"),
              _refreshMethodDropdown(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'The browser has pull to refresh functionality. '
            'However, you can get an extra refresh icon if it\'s useful for certain situations (e.g. '
            'jail or hospital)',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        /*
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Use quick browser"),
              Switch(
                value: _settingsProvider.useQuickBrowser,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeUseQuickBrowser = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Note: this will allow you to open the quick browser in most '
            'places by using a short tap (and long tap for full browser). '
            'This does not apply to the chaining browser and a few other '
            'specific links',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        */
      ],
    );
  }

  Column _tabs() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'TABS',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
          child: Text(
            'Tabs might increase memory and processor usage; be sure that you get familiar with how tabs work (see '
            'the Tips section). It is highly recommended to use tabs to improve your Torn PDA experience.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Use tabs in browser"),
              Switch(
                value: _settingsProvider.useTabsFullBrowser,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeUseTabsFullBrowser = value;
                  });
                  // Reset tabs to shown if we deactivate tabs (so that upon reactivation they show)
                  if (!value) {
                    Prefs().setHideTabs(false);
                  }
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        /*
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Tabs in quick browser"),
              Switch(
                value: _settingsProvider.useTabsBrowserDialog,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeUseTabsBrowserDialog = value;
                  });
                  // Reset tabs to shown if we deactivate tabs in both browsers (so that upon reactivation they show)
                  if (!value || !_settingsProvider.useTabsFullBrowser) {
                    Prefs().setHideTabs(false);
                  }
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        */
        if (_settingsProvider.useTabsFullBrowser)
          Column(
            children: [
              if (_settingsProvider.useTabsFullBrowser)
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text("Only load tabs when used"),
                          Switch(
                            value: _webViewProvider.onlyLoadTabsWhenUsed,
                            onChanged: (value) {
                              _webViewProvider.onlyLoadTabsWhenUsed = value;
                            },
                            activeTrackColor: Colors.lightGreenAccent,
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
                      child: Text(
                        'If active (recommended) not all tabs will load in memory upon browser initialization. Instead, '
                        'they will retrieve the web content when first used (tapped). This could add a small delay when the '
                        'tab is pressed visited the first time, but should improve the overall browser performance. '
                        'Also, tabs that have not been used for 24 hours will be deactivated to reduce memory consumption, '
                        'and will be reactivated with you switch back to them.\n\n'
                        'NOTE: in high performance devices, deactivating this option should make the browser quicker and '
                        'transitions between tabs will be more pleasant, while probably not being noticeable in term of memory usage.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text("Allow hiding tabs"),
                          Switch(
                            value: _settingsProvider.useTabsHideFeature,
                            onChanged: (value) {
                              setState(() {
                                _settingsProvider.changeUseTabsHideFeature = value;
                              });
                              // Show tabs if this feature is disabled
                              if (!value) {
                                Prefs().setHideTabs(false);
                              }
                            },
                            activeTrackColor: Colors.lightGreenAccent,
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
                      child: Text(
                        'Allow to temporarily hide tabs by swiping up/down in the title bar',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        if ((_settingsProvider.useTabsFullBrowser) && _settingsProvider.useTabsHideFeature)
          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    _showColorPickerTabs(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 35, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text("Choose hide bar colour"),
                        Container(
                          width: 25,
                          height: 25,
                          color: Color(_settingsProvider.tabsHideBarColor),
                        )
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Choose the colour of the bar that indicates that tabs are hidden',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Column _fullScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FULL SCREEN BEHAVIOR',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
          child: Text(
            'NOTE: full screen mode is only accessible if using tabs and through the quick menu tab!',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(child: Text("Full screen removes widgets")),
              Switch(
                value: _settingsProvider.fullScreenRemovesWidgets,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenRemovesWidgets = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Dictates whether the full screen mode in the browser, when enabled, should also get rid of all of '
            'Torn PDA widgets',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(child: Text("Full screen removes chat")),
              Switch(
                value: _settingsProvider.fullScreenRemovesChat,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenRemovesChat = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Dictates whether the full screen mode in the browser, when enabled, should also get rid of all of '
            'Torn chat bubbles in game',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(child: Text("Add reload button to tab bar")),
              Switch(
                value: _settingsProvider.fullScreenExtraReloadButton,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenExtraReloadButton = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "When in full screen mode, adds an additional tab with a reload button for a quicker access",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(child: Text("Add close button to tab bar")),
              Switch(
                value: _settingsProvider.fullScreenExtraCloseButton,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenExtraCloseButton = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "When in full screen mode, replaces the 'X' close button in the vertical menu by an additional tab for "
            "a quicker access",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 40,
              width: 50,
              child: Divider(),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FULL SCREEN POSITIONING',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(child: Text("Full screen extends to top")),
              Switch(
                value: _settingsProvider.fullScreenOverNotch,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenOverNotch = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Dictates whether the full screen mode should extend all the way to the top, which might include '
            'the front-facing camera and any other sensors (notch). It will extend the view further, but certain '
            'web elements might be hidden or obscured, as might happen with corners.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(child: Text("Full screen extends to bottom")),
              Switch(
                value: _settingsProvider.fullScreenOverBottom,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenOverBottom = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Dictates whether the full screen mode should extend all the way to the bottom. In certain devices this '
            'might cause the tabs at the corner to be barely reachable.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(child: Text("Full screen extends to sides")),
              Switch(
                value: _settingsProvider.fullScreenOverSides,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenOverSides = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Dictates whether the full screen mode should extend all the way to the sides, including any possible '
            'front-facing cameras, notch, etc. Might be useful for landscape mode.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 40,
              width: 50,
              child: Divider(),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FULL SCREEN INTERACTION',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
          child: Text(
            'NOTE: tabs opened in chaining mode (targets, war targets, loot NPCs, etc.) are not affected by these '
            'options, as chaining controls are needed to advance through the chain.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(child: Text("Short tap opens full screen")),
              Switch(
                value: _settingsProvider.fullScreenByShortTap,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenByShortTap = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Opens the browser in full screen mode when an item in the app is short-tapped. Defaults to OFF.",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(child: Text("Long tap opens full screen")),
              Switch(
                value: _settingsProvider.fullScreenByLongTap,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenByLongTap = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Opens the browser in full screen mode when an item in the app is long-tapped. "
            "Defaults to ON.",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(child: Text("Short/long tab affect PDA icon")),
              Switch(
                value: _settingsProvider.fullScreenIncludesPDAButtonTap,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenIncludesPDAButtonTap = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "By default, the PDA icon in the main pages of the app restores the browser as it was when you left it. "
            "By activating this option, the browser will change to windowed or full screen mode by adhering to "
            "your short and long tap preferences above. Defaults to OFF.",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(child: Text("Notifications open full screen")),
              Switch(
                value: _settingsProvider.fullScreenByNotificationTap,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenByNotificationTap = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Opens the browser in full screen mode when a notification is tapped. Defaults to OFF.",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(child: Text("Deep links open full screen")),
              Switch(
                value: _settingsProvider.fullScreenByDeepLinkTap,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenByDeepLinkTap = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Opens the browser in full screen mode when it has been triggered by a deep link. Defaults to OFF.",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(child: Text("Quick items open full screen")),
              Switch(
                value: _settingsProvider.fullScreenByQuickItemTap,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenByQuickItemTap = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Opens the browser in full screen mode when a quick item (in the app's main icon in your device) has been "
            "tapped.",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  void _showColorPickerTabs(BuildContext context) {
    showDialog(
      useRootNavigator: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color!'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: Color(_settingsProvider.tabsHideBarColor),
              //enableAlpha: false,
              onColorChanged: (color) {
                setState(() {
                  _settingsProvider.changeTabsHideBarColor = color.value;
                });
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Got it'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showColorPickerChat(BuildContext context) {
    var pickerColor = _highlightColor;
    showDialog(
      useRootNavigator: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color!'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _highlightColor,
              //enableAlpha: false,
              onColorChanged: (color) {
                _settingsProvider.changeHighlightColor = color.value;
                setState(() {
                  pickerColor = color;
                });
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Got it'),
              onPressed: () {
                setState(() => _highlightColor = pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      toolbarHeight: 50,
      title: Text('Browser settings'),
      leadingWidth: 80,
      leading: Row(
        children: [
          new IconButton(
            icon: new Icon(Icons.arrow_back),
            onPressed: () {
              _goBack();
            },
          ),
          PdaBrowserIcon(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Widget _browserStyleDropdown() {
    return DropdownButton<int>(
      value: _browserStyle,
      items: [
        DropdownMenuItem(
          value: 0,
          child: SizedBox(
            width: 80,
            child: Text(
              "Default",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 1,
          child: SizedBox(
            width: 80,
            child: Text(
              "Bottom bar",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 2,
          child: SizedBox(
            width: 80,
            child: Text(
              "Dialog",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        if ((_browserStyle != 2 && value == 2) || _browserStyle == 2 && value != 2) {
          // If you go to/from dialog, we will be rebuilding the stackview and therefore the browser will reset
          // to how it was when the app first launched. To force a reload of the last session, just before the change,
          // we transform it into a Container and let the provider change it back to a webview with [recallLastSession]
          _webViewProvider.stackView = Container();
        }

        _browserStyle = value;

        switch (value) {
          case 0:
            analytics.setUserProperty(name: "browser_style", value: "default");
            _webViewProvider.bottomBarStyleEnabled = false;
            break;
          case 1:
            analytics.setUserProperty(name: "browser_style", value: "bottom_bar");
            _webViewProvider.bottomBarStyleEnabled = true;
            _webViewProvider.bottomBarStyleType = 1;
            break;
          case 2:
            analytics.setUserProperty(name: "browser_style", value: "dialog");
            _webViewProvider.bottomBarStyleEnabled = true;
            _webViewProvider.bottomBarStyleType = 2;
            break;
        }
      },
    );
  }

  Widget _refreshMethodDropdown() {
    return DropdownButton<BrowserRefreshSetting>(
      value: _settingsProvider.browserRefreshMethod,
      items: [
        DropdownMenuItem(
          value: BrowserRefreshSetting.icon,
          child: SizedBox(
            width: 100,
            child: Text(
              "Icon",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: BrowserRefreshSetting.pull,
          child: SizedBox(
            width: 100,
            child: Text(
              "Pull to refresh",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: BrowserRefreshSetting.both,
          child: SizedBox(
            width: 100,
            child: Text(
              "Both",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _settingsProvider.changeBrowserRefreshMethod = value;
          _webViewProvider.updatePullToRefresh(value);
        });
      },
    );
  }

  DropdownButton _profileStatsDropdown() {
    return DropdownButton<String>(
      value: _settingsProvider.profileStatsEnabled,
      items: [
        DropdownMenuItem(
          value: "0",
          child: SizedBox(
            width: 80,
            child: Text(
              "All stats",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "2",
          child: SizedBox(
            width: 80,
            child: Text(
              "Spied only",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "1",
          child: SizedBox(
            width: 80,
            child: Text(
              "Hide",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _settingsProvider.changeProfileStatsEnabled = value;
        });
      },
    );
  }

  Future _restorePreferences() async {
    var alternativeBrowser = await Prefs().getBrowserBottomBarStyleEnabled();
    var alternativeType = await Prefs().getBrowserBottomBarStyleType();
    var style = 0;
    if (alternativeBrowser) {
      style = alternativeType == 2 ? 2 : 1;
    }

    setState(() {
      _highlightChat = _settingsProvider.highlightChat;
      _highlightColor = Color(_settingsProvider.highlightColor);
      _browserStyle = style;
    });
  }

  _goBack() {
    routeWithDrawer = true;
    routeName = "settings";
    Navigator.of(context).pop();
  }
}
