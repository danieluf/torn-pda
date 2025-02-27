// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:animations/animations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/webviews/chaining_payload.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';
import 'package:url_launcher/url_launcher.dart';

// Project imports:
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/pages/chaining/target_details_page.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/html_parser.dart';
import '../../utils/country_check.dart';
import '../notes_dialog.dart';

class TargetCard extends StatefulWidget {
  final TargetModel targetModel;

  // Key is needed to update at least the hospital counter individually
  TargetCard({@required this.targetModel, @required Key key}) : super(key: key);

  @override
  _TargetCardState createState() => _TargetCardState();
}

class _TargetCardState extends State<TargetCard> {
  TargetModel _target;
  TargetsProvider _targetsProvider;
  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;
  UserDetailsProvider _userProvider;
  ChainStatusProvider _chainProvider;
  WebViewProvider _webViewProvider;

  Timer _updatedTicker;
  Timer _lifeTicker;

  String _currentLifeString = "";
  String _lastUpdatedString;
  int _lastUpdatedMinutes;

  @override
  void initState() {
    super.initState();
    _webViewProvider = context.read<WebViewProvider>();
    _updatedTicker = new Timer.periodic(Duration(seconds: 60), (Timer t) => _timerUpdateInformation());
    _chainProvider = Provider.of<ChainStatusProvider>(context, listen: false);
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
    _targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _updatedTicker?.cancel();
    _lifeTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _target = widget.targetModel;
    _returnLastUpdated();
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: _borderColor(),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(4.0),
        ),
        elevation: 2,
        child: ClipPath(
          clipper: ShapeBorderClipper(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: _chainProvider.panicTargets.where((t) => t.name == _target.name).length > 0
                      ? Colors.blue
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // LINE 1
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(12, 5, 10, 0),
                  child: Row(
                    children: <Widget>[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          GestureDetector(
                            onTap: () {
                              if (_target.status.state.contains("Federal") || _target.status.state.contains("Fallen")) {
                                BotToast.showText(
                                  text: "This player is "
                                      "${_target.status.state.replaceAll("Federal", "in federal jail").toLowerCase()}"
                                      " and cannot be attacked!",
                                  textStyle: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  contentColor: Colors.red,
                                  duration: Duration(seconds: 5),
                                  contentPadding: EdgeInsets.all(10),
                                );
                              } else {
                                _startAttack();
                              }
                            },
                            child: Row(
                              children: [
                                if (_target.status.state.contains("Federal") || _target.status.state.contains("Fallen"))
                                  Icon(MdiIcons.graveStone, size: 18)
                                else
                                  _attackIcon(),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 5),
                                ),
                                SizedBox(
                                  width: 95,
                                  child: Text(
                                    '${_target.name}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 5),
                                OpenContainer(
                                  transitionDuration: Duration(milliseconds: 500),
                                  transitionType: ContainerTransitionType.fadeThrough,
                                  openBuilder: (BuildContext context, VoidCallback _) {
                                    return TargetDetailsPage(target: _target);
                                  },
                                  closedElevation: 0,
                                  closedShape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(56 / 2),
                                    ),
                                  ),
                                  closedColor: Colors.transparent,
                                  openColor: _themeProvider.canvas,
                                  closedBuilder: (BuildContext context, VoidCallback openContainer) {
                                    return SizedBox(
                                      height: 22,
                                      width: 30,
                                      child: Icon(
                                        Icons.info_outline,
                                        size: 20,
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(width: 5),
                                _factionIcon(),
                              ],
                            ),
                            Text(
                              'Lvl ${_target.level}',
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 3),
                              child: SizedBox(
                                height: 22,
                                width: 22,
                                child: _refreshIcon(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // LINE 2
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16, 5, 15, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      _returnRespectFF(_target.respectGain, _target.fairFight),
                      _returnHealth(_target),
                    ],
                  ),
                ),
                // LINE 3
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(15, 5, 15, 0),
                  child: Row(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          _travelIcon(),
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _returnStatusColor(_target.lastAction.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 13),
                            child: Text(
                              _target.lastAction.relative == "0 minutes ago"
                                  ? 'now'
                                  : _target.lastAction.relative.replaceAll(' ago', ''),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Icon(Icons.refresh, size: 15),
                            Text(
                              ' $_lastUpdatedString',
                              style: TextStyle(
                                color: _lastUpdatedMinutes <= 120 ? _themeProvider.mainText : Colors.deepOrangeAccent,
                                fontStyle: _lastUpdatedMinutes <= 120 ? FontStyle.normal : FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // LINE 4
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(8, 5, 15, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 30,
                              height: 20,
                              child: IconButton(
                                padding: EdgeInsets.all(0),
                                iconSize: 20,
                                icon: Icon(
                                  MdiIcons.notebookEditOutline,
                                  color: _returnTargetNoteColor(),
                                ),
                                onPressed: () {
                                  _showNotesDialog();
                                },
                              ),
                            ),
                            SizedBox(width: 4),
                            Text('Notes: '),
                            Flexible(
                              child: Text(
                                '${_target.personalNote}',
                                style: TextStyle(
                                  color: _returnTargetNoteColor(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Text(
                          '${_targetsProvider.allTargets.indexOf(_target) + 1}'
                          '/${_targetsProvider.allTargets.length}',
                          style: TextStyle(
                            color: Colors.brown[400],
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _attackIcon() {
    return SizedBox(
      height: 20,
      width: 20,
      child: Image.asset(
        'images/icons/ic_target_account_black_48dp.png',
        color: Colors.red,
        width: 20,
      ),
    );
  }

  Widget _refreshIcon() {
    if (_target.isUpdating) {
      return Padding(
        padding: const EdgeInsets.all(4.0),
        child: CircularProgressIndicator(),
      );
    } else {
      return IconButton(
        padding: EdgeInsets.all(0.0),
        iconSize: 22,
        icon: Icon(Icons.refresh),
        onPressed: () async {
          _updateThisTarget();
        },
      );
    }
  }

  Widget _factionIcon() {
    if (_target.hasFaction) {
      Color borderColor = Colors.transparent;
      Color iconColor = _themeProvider.mainText;
      if (_target.faction.factionId == _userProvider.basic.faction.factionId) {
        borderColor = iconColor = Colors.green[500];
      }

      void showFactionToast() {
        if (_target.faction.factionId == _userProvider.basic.faction.factionId) {
          BotToast.showText(
            text: HtmlParser.fix("${_target.name} belongs to your same faction "
                "(${_target.faction.factionName}) as "
                "${_target.faction.position}"),
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.green,
            duration: Duration(seconds: 5),
            contentPadding: EdgeInsets.all(10),
          );
        } else {
          BotToast.showText(
            text: HtmlParser.fix("${_target.name} belongs to faction "
                "${_target.faction.factionName} as "
                "${_target.faction.position}"),
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.grey[600],
            duration: Duration(seconds: 5),
            contentPadding: EdgeInsets.all(10),
          );
        }
      }

      Widget factionIcon = Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
            shape: BoxShape.circle,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: () {
              showFactionToast();
            },
            child: Padding(
              padding: EdgeInsets.all(2),
              child: ImageIcon(
                AssetImage('images/icons/faction.png'),
                size: 12,
                color: iconColor,
              ),
            ),
          ),
        ),
      );
      return factionIcon;
    } else {
      return SizedBox.shrink();
    }
  }

  Color _borderColor() {
    if (_target.justUpdatedWithSuccess) {
      return Colors.green;
    } else if (_target.justUpdatedWithError) {
      return Colors.red;
    } else {
      return Colors.transparent;
    }
  }

  Widget _returnRespectFF(double respect, double fairFight) {
    TextSpan respectResult;
    TextSpan fairFightResult;

    if (respect == -1) {
      respectResult = TextSpan(
        text: 'unk',
        style: TextStyle(
          color: _themeProvider.mainText,
        ),
      );
    } else if (respect == 0) {
      if (_target.userWonOrDefended) {
        respectResult = TextSpan(
          text: '0 (def)',
          style: TextStyle(
            color: _themeProvider.mainText,
          ),
        );
      } else {
        respectResult = TextSpan(
          text: 'Lost',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        );
      }
    } else {
      respectResult = TextSpan(
        text: respect.toStringAsFixed(2),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: _themeProvider.mainText,
        ),
      );
    }

    if (fairFight == -1) {
      fairFightResult = TextSpan(
        text: 'unk',
        style: TextStyle(
          color: _themeProvider.mainText,
        ),
      );
    } else {
      var ffColor = Colors.red;
      if (fairFight >= 2.2 && fairFight < 2.8) {
        ffColor = Colors.orange;
      } else if (fairFight >= 2.8) {
        ffColor = Colors.green;
      }

      fairFightResult = TextSpan(
        text: fairFight.toStringAsFixed(2),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: ffColor,
        ),
      );
    }

    return Flexible(
      child: Row(
        children: [
          Flexible(
            child: RichText(
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                    text: 'R: ',
                    style: TextStyle(
                      color: _themeProvider.mainText,
                    ),
                  ),
                  respectResult,
                ],
              ),
            ),
          ),
          respect == 0
              ? SizedBox.shrink()
              : Flexible(
                  child: RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: ' / FF: ',
                          style: TextStyle(
                            color: _themeProvider.mainText,
                          ),
                        ),
                        fairFightResult,
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _returnHealth(TargetModel target) {
    Color lifeBarColor = Colors.green;
    Widget hospitalWarning = SizedBox.shrink();
    String lifeText = _target.life.current.toString();

    if (target.status.state == "Hospital") {
      // Handle if target is still in hospital
      var now = (DateTime.now().millisecondsSinceEpoch / 1000).floor();

      if (target.status.until > now) {
        var endTimeStamp = DateTime.fromMillisecondsSinceEpoch(target.status.until * 1000);
        if (_lifeTicker == null) {
          _lifeTicker = Timer.periodic(Duration(seconds: 1), (Timer t) => _refreshLifeClock(endTimeStamp));
        }
        _refreshLifeClock(endTimeStamp);
        lifeText = _currentLifeString;
        lifeBarColor = Colors.red[300];
        hospitalWarning = Icon(
          Icons.local_hospital,
          size: 20,
          color: Colors.red,
        );
      } else {
        _lifeTicker?.cancel();
        lifeText = "OUT";
        hospitalWarning = Icon(
          MdiIcons.bandage,
          size: 20,
          color: Colors.green,
        );
      }
    } else {
      _lifeTicker?.cancel();
    }

    double lifePercentage;

    // Avoid issues with dormant NPC reporting weird life values (0)
    if (_target.life.current == 0 || _target.life.maximum == 0) {
      lifePercentage = 0;
    } else {
      // Found players in federal jail with a higher life than their maximum. Correct it if it's the
      // case to avoid issues with percentage bar
      if (_target.life.current / _target.life.maximum > 1) {
        lifePercentage = 1;
      } else if (_target.life.current / _target.life.maximum > 1) {
        lifePercentage = 0;
      } else {
        lifePercentage = _target.life.current / _target.life.maximum;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Life ',
        ),
        LinearPercentIndicator(
          padding: null,
          barRadius: Radius.circular(10),
          width: 100,
          lineHeight: 16,
          progressColor: lifeBarColor,
          center: Text(
            lifeText,
            style: TextStyle(color: Colors.black, fontSize: 12),
          ),
          percent: lifePercentage,
        ),
        hospitalWarning,
      ],
    );
  }

  Widget _travelIcon() {
    var country = countryCheck(state: _target.status.state, description: _target.status.description);

    if (_target.status.color == "blue" || (country != "Torn" && _target.status.color == "red")) {
      var destination = _target.status.color == "blue" ? _target.status.description : country;
      var flag = '';
      if (destination.contains('Japan')) {
        flag = 'images/flags/stock/japan.png';
      } else if (destination.contains('Hawaii')) {
        flag = 'images/flags/stock/hawaii.png';
      } else if (destination.contains('China')) {
        flag = 'images/flags/stock/china.png';
      } else if (destination.contains('Argentina')) {
        flag = 'images/flags/stock/argentina.png';
      } else if (destination.contains('United Kingdom')) {
        flag = 'images/flags/stock/uk.png';
      } else if (destination.contains('Cayman')) {
        flag = 'images/flags/stock/cayman.png';
      } else if (destination.contains('South Africa')) {
        flag = 'images/flags/stock/south-africa.png';
      } else if (destination.contains('Switzerland')) {
        flag = 'images/flags/stock/switzerland.png';
      } else if (destination.contains('Mexico')) {
        flag = 'images/flags/stock/mexico.png';
      } else if (destination.contains('UAE')) {
        flag = 'images/flags/stock/uae.png';
      } else if (destination.contains('Canada')) {
        flag = 'images/flags/stock/canada.png';
      }

      return Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: () {
            BotToast.showText(
              text: _target.status.description,
              textStyle: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.blue,
              duration: Duration(seconds: 5),
              contentPadding: EdgeInsets.all(10),
            );
          },
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: RotatedBox(
                  quarterTurns: _target.status.description.contains('Traveling to ')
                      ? 1 // If traveling to another country
                      : _target.status.description.contains('Returning ')
                          ? 3 // If returning to Torn
                          : 0, // If staying abroad (blue but not moving)
                  child: Icon(
                    _target.status.description.contains('In ')
                        ? Icons.location_city_outlined
                        : Icons.airplanemode_active,
                    color: Colors.blue,
                    size: 16,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Image.asset(
                  flag,
                  width: 16,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Color _returnStatusColor(String status) {
    switch (status) {
      case 'Online':
        return Colors.green;
        break;
      case 'Idle':
        return Colors.orange;
        break;
      default:
        return Colors.grey;
    }
  }

  void _returnLastUpdated() {
    var timeDifference = DateTime.now().difference(_target.lastUpdated);
    _lastUpdatedMinutes = timeDifference.inMinutes;
    if (timeDifference.inMinutes < 1) {
      _lastUpdatedString = 'now';
    } else if (timeDifference.inMinutes == 1 && timeDifference.inHours < 1) {
      _lastUpdatedString = '1 minute ago';
    } else if (timeDifference.inMinutes > 1 && timeDifference.inHours < 1) {
      _lastUpdatedString = '${timeDifference.inMinutes} minutes ago';
    } else if (timeDifference.inHours == 1 && timeDifference.inDays < 1) {
      _lastUpdatedString = '1 hour ago';
    } else if (timeDifference.inHours > 1 && timeDifference.inDays < 1) {
      _lastUpdatedString = '${timeDifference.inHours} hours ago';
    } else if (timeDifference.inDays == 1) {
      _lastUpdatedString = '1 day ago';
    } else {
      _lastUpdatedString = '${timeDifference.inDays} days ago';
    }
  }

  Color _returnTargetNoteColor() {
    switch (_target.personalNoteColor) {
      case 'red':
        return Colors.red[600];
        break;
      case 'orange':
        return Colors.orange[600];
        break;
      case 'green':
        return Colors.green[600];
        break;
      default:
        return _themeProvider.mainText;
        break;
    }
  }

  Future<void> _showNotesDialog() {
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
              child: PersonalNotesDialog(
                targetModel: _target,
                noteType: PersonalNoteType.target,
              ),
            ),
          );
        });
  }

  void _updateThisTarget() async {
    bool updateWorked = await _targetsProvider.updateTarget(
      targetToUpdate: _target,
      attacks: await _targetsProvider.getAttacks(),
    );
    if (updateWorked) {
    } else {
      BotToast.showText(
        text: "Error updating ${_target.name}!",
        textStyle: TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.red,
        duration: Duration(seconds: 3),
        contentPadding: EdgeInsets.all(10),
      );
    }
  }

  void _timerUpdateInformation() {
    _returnLastUpdated();
    if (mounted) {
      setState(() {});
    }
  }

  _refreshLifeClock(DateTime timeEnd) {
    var diff = timeEnd.difference(DateTime.now());
    if (diff.inSeconds > 0) {
      Duration timeOut = Duration(seconds: diff.inSeconds);

      String timeOutMin = timeOut.inMinutes.remainder(60).toString();
      if (timeOut.inMinutes.remainder(60) < 10) {
        timeOutMin = '0$timeOutMin';
      }

      String timeOutSec = timeOut.inSeconds.remainder(60).toString();
      if (timeOut.inSeconds.remainder(60) < 10) {
        timeOutSec = '0$timeOutSec';
      }

      int timerCadence = 1;
      if (diff.inSeconds > 80) {
        timerCadence = 20;
        if (mounted) {
          setState(() {
            _currentLifeString = '${timeOut.inHours}h ${timeOutMin}m';
          });
        }
      } else if (diff.inSeconds > 59 && diff.inSeconds <= 80) {
        timerCadence = 1;
      } else {
        timerCadence = 1;
        if (mounted) {
          setState(() {
            _currentLifeString = '$timeOutSec sec';
          });
        }
      }

      if (_lifeTicker != null) {
        _lifeTicker.cancel();
        _lifeTicker = Timer.periodic(Duration(seconds: timerCadence), (Timer t) => _refreshLifeClock(timeEnd));
      }

      if (diff.inSeconds < 2) {
        // Artificially release instead of updating
        _releaseFromHospital();
      }
    }
  }

  _releaseFromHospital() async {
    await Future.delayed(const Duration(seconds: 5));
    if (_lifeTicker != null) {
      _lifeTicker.cancel();
    }
    _target.status.until = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
    if (mounted) {
      setState(() {});
    }
  }

  void _startAttack() async {
    var browserType = _settingsProvider.currentBrowser;
    switch (browserType) {
      case BrowserSetting.app:
        // For app browser, we are going to pass a list of attacks
        // so that we can move to the next one
        var myTargetList = List<TargetModel>.from(_targetsProvider.allTargets);
        // First, find out where we are in the list
        for (var i = 0; i < myTargetList.length; i++) {
          if (_target.playerId == myTargetList[i].playerId) {
            myTargetList.removeRange(0, i);
            break;
          }
        }
        List<String> attacksIds = <String>[];
        List<String> attacksNames = <String>[];
        List<String> attackNotes = <String>[];
        List<String> attacksNotesColor = <String>[];
        for (var tar in myTargetList) {
          attacksIds.add(tar.playerId.toString());
          attacksNames.add(tar.name);
          attackNotes.add(tar.personalNote);
          attacksNotesColor.add(tar.personalNoteColor);
        }

        bool showNotes = await Prefs().getShowTargetsNotes();
        bool showBlankNotes = await Prefs().getShowBlankTargetsNotes();
        bool showOnlineFactionWarning = await Prefs().getShowOnlineFactionWarning();

        _webViewProvider.openBrowserPreference(
          context: context,
          url: 'https://www.torn.com/loader.php?sid=attack&user2ID=${attacksIds[0]}',
          browserTapType: BrowserTapType.chain,
          recallLastSession: false,
          isChainingBrowser: true,
          chainingPayload: ChainingPayload()
            ..attackIdList = attacksIds
            ..attackNameList = attacksNames
            ..attackNotesList = attackNotes
            ..attackNotesColorList = attacksNotesColor
            ..showNotes = showNotes
            ..showBlankNotes = showBlankNotes
            ..showOnlineFactionWarning = showOnlineFactionWarning,
        );

        break;
      case BrowserSetting.external:
        var url = 'https://www.torn.com/loader.php?sid='
            'attack&user2ID=${_target.playerId}';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
        break;
    }
  }
}
