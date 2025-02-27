import 'package:flutter/material.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';

import 'foreign_stock_button.dart';

class ArrivalButton extends StatefulWidget {
  final OwnProfileExtended user;
  final ThemeProvider themeProvider;
  final UserDetailsProvider userProv;
  final SettingsProvider settingsProv;
  final Function launchBrowser;
  final Function updateCallback;

  const ArrivalButton({
    @required this.user,
    @required this.themeProvider,
    @required this.userProv,
    @required this.settingsProv,
    @required this.launchBrowser({String url, bool shortTap}),
    @required this.updateCallback,
    Key key,
  }) : super(key: key);

  @override
  _ArrivalButtonState createState() => _ArrivalButtonState();
}

class _ArrivalButtonState extends State<ArrivalButton> with TickerProviderStateMixin {
  AnimationController _resizableController;

  @override
  void initState() {
    _resizableController = new AnimationController(
      vsync: this,
      duration: new Duration(
        milliseconds: 1000,
      ),
    );
    _resizableController.addStatusListener((animationStatus) {
      switch (animationStatus) {
        case AnimationStatus.completed:
          _resizableController.reverse();
          break;
        case AnimationStatus.dismissed:
          _resizableController.forward();
          break;
        case AnimationStatus.forward:
          break;
        case AnimationStatus.reverse:
          break;
      }
    });
    _resizableController.forward();
    super.initState();
  }

  @override
  void dispose() {
    _resizableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedBuilder(
            animation: _resizableController,
            builder: (context, child) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  primary: widget.themeProvider.cardColor,
                  side: BorderSide(
                    width: _resizableController.value * 8,
                    color: Colors.orange,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flight_land,
                      size: 22,
                      color: widget.themeProvider.mainText,
                    ),
                    SizedBox(width: 6),
                    Column(
                      children: [
                        Text(
                          "APPROACHING",
                          style: TextStyle(
                            fontSize: 8,
                            color: widget.themeProvider.mainText,
                          ),
                        ),
                        Text(
                          widget.user.travel.destination.toUpperCase(),
                          style: TextStyle(
                            fontSize: 8,
                            color: widget.themeProvider.mainText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                onLongPress: () {
                  widget.launchBrowser(url: 'https://www.torn.com', shortTap: true);
                },
                onPressed: () async {
                  widget.launchBrowser(url: 'https://www.torn.com', shortTap: false);
                },
              );
            }),
        SizedBox(width: 20),
        ForeignStockButton(
          userProv: widget.userProv,
          settingsProv: widget.settingsProv,
          launchBrowser: widget.launchBrowser,
          updateCallback: widget.updateCallback,
        ),
      ],
    );
  }
}
