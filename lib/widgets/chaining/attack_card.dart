// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';

// Project imports:
import 'package:torn_pda/models/chaining/attack_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/html_parser.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

class AttackCard extends StatefulWidget {
  final Attack attackModel;

  AttackCard({@required this.attackModel});

  @override
  _AttackCardState createState() => _AttackCardState();
}

class _AttackCardState extends State<AttackCard> {
  Attack _attack;
  ThemeProvider _themeProvider;
  UserDetailsProvider _userProvider;

  bool _addButtonActive = true;

  @override
  Widget build(BuildContext context) {
    _attack = widget.attackModel;
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.0),
        ),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // LINE 1
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(15, 5, 15, 0),
              child: Row(
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        height: 20,
                        width: _attack.targetName.isNotEmpty ? 20 : 0,
                        child: _attack.targetName.isNotEmpty
                            ? GestureDetector(
                                child: Icon(
                                  Icons.remove_red_eye,
                                  size: 20,
                                ),
                                onTap: () async {
                                  var url = 'https://www.torn.com/profiles.php?XID=${_attack.targetId}';
                                  await context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.short,
                                      );
                                },
                                onLongPress: () async {
                                  var url = 'https://www.torn.com/profiles.php?XID=${_attack.targetId}';
                                  await context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.long,
                                      );
                                },
                              )
                            : SizedBox.shrink(),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                      ),
                      SizedBox(
                        width: _attack.targetName.isNotEmpty ? 70 : 175,
                        child: Text(
                          _attack.targetName.isNotEmpty ? '${_attack.targetName}' : "anonymous",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: _attack.targetName.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                            fontStyle: _attack.targetName.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        SizedBox(
                          width: _attack.targetName.isNotEmpty ? 85 : 0,
                          child: Text(
                            _attack.targetName.isNotEmpty ? ' [${_attack.targetId}]' : "",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        _returnTargetLevel(),
                        Row(
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: _factionIcon(),
                            ),
                            SizedBox(width: 5),
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: _attack.targetName.isNotEmpty ? _returnAddTargetButton() : SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // LINE 2
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(15, 5, 15, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(_returnDateFormatted()),
                  _returnRespect(),
                ],
              ),
            ),
            // LINE 3
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(15, 5, 15, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: [
                      Text('Last results: '),
                      _returnLastResults(),
                    ],
                  ),
                  _returnFairFight(),
                ],
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _returnAddTargetButton() {
    bool existingTarget = false;

    var targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
    var targetList = targetsProvider.allTargets;
    for (var tar in targetList) {
      if (tar.playerId.toString() == _attack.targetId) {
        existingTarget = true;
      }
    }

    if (existingTarget) {
      return IconButton(
        padding: EdgeInsets.all(0.0),
        iconSize: 20,
        icon: Icon(
          Icons.remove_circle_outline,
          color: Colors.red,
        ),
        onPressed: () {
          targetsProvider.deleteTargetById(_attack.targetId);
          BotToast.showText(
            text: HtmlParser.fix('Removed ${_attack.targetName}!'),
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.orange[900],
            duration: Duration(seconds: 5),
            contentPadding: EdgeInsets.all(10),
          );
          // Update the button
          setState(() {});
        },
      );
    } else {
      return IconButton(
        padding: EdgeInsets.all(0.0),
        iconSize: 20,
        icon: _addButtonActive
            ? Icon(
                Icons.add_circle_outline,
                color: Colors.green,
              )
            : SizedBox(
                height: 15,
                width: 15,
                child: CircularProgressIndicator(),
              ),
        onPressed: () async {
          setState(() {
            _addButtonActive = false;
          });

          AddTargetResult tryAddTarget = await targetsProvider.addTarget(
            targetId: _attack.targetId,
            attacks: await targetsProvider.getAttacks(),
          );
          if (tryAddTarget.success) {
            BotToast.showText(
              text: HtmlParser.fix('Added ${tryAddTarget.targetName} [${tryAddTarget.targetId}]'),
              textStyle: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.green[700],
              duration: Duration(seconds: 5),
              contentPadding: EdgeInsets.all(10),
            );
            // Update the button
            if (mounted) {
              setState(() {
                _addButtonActive = true;
              });
            }
          } else if (!tryAddTarget.success) {
            BotToast.showText(
              text: HtmlParser.fix('Error adding ${_attack.targetId}. ${tryAddTarget.errorReason}'),
              textStyle: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.red[900],
              duration: Duration(seconds: 5),
              contentPadding: EdgeInsets.all(10),
            );
          }
        },
      );
    }
  }

  Widget _returnTargetLevel() {
    if (_attack.attackInitiated) {
      if (_attack.attackWon) {
        return Text('Level ${_attack.targetLevel}');
      } else {
        return Text('[lost]',
            style: TextStyle(
              fontSize: 13,
              color: Colors.red,
            ));
      }
    } else {
      if (_attack.attackWon) {
        return Text('[lost]',
            style: TextStyle(
              fontSize: 13,
              color: Colors.red,
            ));
      } else {
        return Text(
          '[defended]',
          style: TextStyle(fontSize: 13),
        );
      }
    }
  }

  String _returnDateFormatted() {
    var date = new DateTime.fromMillisecondsSinceEpoch(_attack.timestampEnded * 1000);
    var formatter = new DateFormat('dd MMMM HH:mm');
    return formatter.format(date);
  }

  Widget _returnRespect() {
    dynamic respect = _attack.respectGain;
    if (respect is String) {
      respect = double.parse(respect);
    }

    TextSpan respectSpan;
    if ((_attack.attackInitiated && !_attack.attackWon) || (!_attack.attackInitiated && _attack.attackWon)) {
      // If we attacked and lost, or someone attacked us and won
      // we just show '0' but in red to indicate that we lost
      respectSpan = TextSpan(
        text: '0',
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (_attack.attackInitiated && _attack.attackWon) {
      // If we attacked and won, we show the actual respect
      respectSpan = TextSpan(
        text: respect.toStringAsFixed(2),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: _themeProvider.mainText,
        ),
      );
    } else {
      // Else (if someone attacked and lost (we defended successfully), we
      // don't gain any respect at all
      respectSpan = TextSpan(
        text: '0',
        style: TextStyle(
          color: _themeProvider.mainText,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        children: <TextSpan>[
          TextSpan(
            text: 'Respect: ',
            style: TextStyle(
              color: _themeProvider.mainText,
            ),
          ),
          respectSpan,
        ],
      ),
    );
  }

  Widget _returnFairFight() {
    dynamic ff = _attack.modifiers.fairFight;
    if (ff is String) {
      ff = double.parse(ff);
    }

    var ffColor = Colors.red;
    if (ff >= 2.2 && ff < 2.8) {
      ffColor = Colors.orange;
    } else if (ff >= 2.8) {
      ffColor = Colors.green;
    }

    TextSpan ffSpan;
    ffSpan = TextSpan(
      text: ff.toString(),
      style: TextStyle(
        color: ffColor,
        fontWeight: FontWeight.bold,
      ),
    );

    return RichText(
      text: TextSpan(
        children: <TextSpan>[
          TextSpan(
            text: 'Fair Fight: ',
            style: TextStyle(
              color: _themeProvider.mainText,
            ),
          ),
          ffSpan,
        ],
      ),
    );
  }

  Widget _returnLastResults() {
    var results = <Widget>[];

    Widget firstResult = Padding(
      padding: EdgeInsets.only(left: 3, right: 8, top: 1),
      child: Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(
            color: _attack.attackSeriesGreen[0] ? Colors.green : Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black)),
      ),
    );

    results.add(firstResult);

    if (_attack.attackSeriesGreen.length > 1) {
      for (var i = 1; i < _attack.attackSeriesGreen.length; i++) {
        if (i == 10) {
          break;
        }

        Widget anotherResult = Padding(
          padding: EdgeInsets.only(right: 5, top: 2),
          child: Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
                color: _attack.attackSeriesGreen[i] ? Colors.green : Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black)),
          ),
        );

        results.add(anotherResult);
      }
    }

    return Row(children: results);
  }

  Widget _factionIcon() {
    String factionName = "";
    int factionId = 0;
    if (_attack.attackInitiated) {
      if (_attack.defenderFactionname != null && _attack.defenderFactionname != "") {
        factionName = _attack.defenderFactionname;
        factionId = _attack.defenderFaction;
      } else {
        return SizedBox.shrink();
      }
    } else {
      if (_attack.attackerFactionname != null && _attack.attackerFactionname != "") {
        factionName = _attack.attackerFactionname;
        factionId = _attack.attackerFaction;
      } else {
        return SizedBox.shrink();
      }
    }

    Color borderColor = Colors.transparent;
    Color iconColor = _themeProvider.mainText;
    if (factionId == _userProvider.basic.faction.factionId) {
      borderColor = iconColor = Colors.green[500];
    }

    void showFactionToast() {
      if (factionId == _userProvider.basic.faction.factionId) {
        BotToast.showText(
          text: HtmlParser.fix("${_attack.targetName} belongs to your same faction ($factionName)"),
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
          text: HtmlParser.fix("${_attack.targetName} belongs to faction $factionName"),
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
  }
}
