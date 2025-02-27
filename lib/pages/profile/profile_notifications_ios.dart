// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';

// Project imports:
import 'package:torn_pda/pages/profile/hospital_ahead_options.dart';
import 'package:torn_pda/pages/profile/jail_ahead_options.dart';
import 'package:torn_pda/pages/profile_page.dart';
import 'package:torn_pda/pages/travel/travel_options_android.dart';
import 'package:torn_pda/pages/travel/travel_options_ios.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class ProfileNotificationsIOS extends StatefulWidget {
  final Function callback;
  final int energyMax;
  final int nerveMax;

  ProfileNotificationsIOS({
    @required this.callback,
    @required this.energyMax,
    @required this.nerveMax,
  });

  @override
  _ProfileNotificationsIOSState createState() => _ProfileNotificationsIOSState();
}

class _ProfileNotificationsIOSState extends State<ProfileNotificationsIOS> {
  final _energyMin = 10.0;
  final _nerveMin = 2.0;

  int _energyDivisions;

  double _energyTrigger;
  double _nerveTrigger;

  Future _preferencesLoaded;

  SettingsProvider _settingsProvider;
  ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _preferencesLoaded = _restorePreferences();

    routeName = "profile_notifications";
    routeWithDrawer = false;
    _settingsProvider.willPopShouldGoBack.stream.listen((event) {
      if (mounted && routeName == "profile_notifications") _goBack();
    });
  }

  @override
  Widget build(BuildContext context) {
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
          body: Builder(
            builder: (BuildContext context) {
              return Container(
                color: _themeProvider.canvas,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
                  child: FutureBuilder(
                    future: _preferencesLoaded,
                    builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return SingleChildScrollView(
                          child: Column(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text('Here you can specify your preferred alerting '
                                    'values for each type of event.'),
                              ),
                              _rowsWithTypes(),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50,
                                  vertical: 20,
                                ),
                                child: Divider(),
                              ),
                              SizedBox(height: 50),
                            ],
                          ),
                        );
                      } else {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: Text("Notification options"),
      leading: new IconButton(
        icon: new Icon(Icons.arrow_back),
        onPressed: () {
          _goBack();
        },
      ),
    );
  }

  Widget _rowsWithTypes() {
    var types = <Widget>[];
    ProfileNotification.values.forEach((element) {
      if (element == ProfileNotification.travel) {
        types.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("Travel timings & text"),
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_right_outlined),
                  onPressed: () {
                    if (Platform.isAndroid) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return TravelOptionsAndroid();
                          },
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return TravelOptionsIOS();
                          },
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
        types.add(SizedBox(height: 10));
      }

      if (element == ProfileNotification.energy) {
        types.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Energy'),
                Padding(
                  padding: EdgeInsets.only(left: 20),
                ),
                Row(
                  children: <Widget>[
                    Text('E${_energyTrigger.floor()}'),
                    Slider(
                      value: _energyTrigger.toDouble(),
                      min: _energyMin,
                      max: widget.energyMax.toDouble(),
                      divisions: _energyDivisions,
                      onChanged: (double newValue) {
                        setState(() {
                          _energyTrigger = newValue;
                        });
                      },
                      onChangeEnd: (double finalValue) {
                        Prefs().setEnergyNotificationValue(finalValue.floor());
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }

      if (element == ProfileNotification.nerve) {
        types.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Nerve'),
                Padding(
                  padding: EdgeInsets.only(left: 20),
                ),
                Row(
                  children: <Widget>[
                    Text('N${_nerveTrigger.floor()}'),
                    Slider(
                      value: _nerveTrigger.toDouble(),
                      min: _nerveMin,
                      max: widget.nerveMax.toDouble(),
                      onChanged: (double newValue) {
                        setState(() {
                          _nerveTrigger = newValue;
                        });
                      },
                      onChangeEnd: (double finalValue) {
                        Prefs().setNerveNotificationValue(finalValue.floor());
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }

      if (element == ProfileNotification.hospital) {
        types.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("Hospital notification timings"),
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_right_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return HospitalAheadOptions();
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
        types.add(SizedBox(height: 10));
      }

      if (element == ProfileNotification.jail) {
        types.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("Jail notification timings"),
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_right_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return JailAheadOptions();
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
        types.add(SizedBox(height: 10));
      }

      if (element == ProfileNotification.rankedWar) {
        types.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("Ranked War notification timings"),
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_right_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return JailAheadOptions();
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
        types.add(SizedBox(height: 10));
      }
    });

    return Column(
      children: types,
    );
  }

  Future _restorePreferences() async {
    var energyTrigger = await Prefs().getEnergyNotificationValue();
    // In case we pass some incorrect values, we correct them here
    if (energyTrigger < _energyMin || energyTrigger > widget.energyMax) {
      energyTrigger = widget.energyMax;
    }

    var nerveTrigger = await Prefs().getNerveNotificationValue();
    // In case we pass some incorrect values, we correct them here
    if (nerveTrigger < _nerveMin || nerveTrigger > widget.nerveMax) {
      nerveTrigger = widget.nerveMax;
    }

    setState(() {
      _energyDivisions = ((widget.energyMax - _energyMin) / 5).floor();
      _energyTrigger = energyTrigger.toDouble();
      _nerveTrigger = nerveTrigger.toDouble();
    });
  }

  _goBack() async {
    if (widget.callback != null) {
      widget.callback();
    }
    routeName = "profile_options";
    routeWithDrawer = false;
    Navigator.of(context).pop();
  }
}
