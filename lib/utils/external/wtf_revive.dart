// Dart imports:
import 'dart:convert';
import 'dart:developer';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:http/http.dart' as http;

// Project imports:
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/profile/revive_services/wtf_revive_model.dart';

class WtfRevive {
  int tornId;
  String username;
  String faction;
  String country;

  WtfRevive({
    @required this.tornId,
    @required this.username,
    @required this.faction,
    @required this.country,
  });

  Future<List<String>> callMedic() async {
    var modelOut = WtfReviveModel()
      ..userId = tornId.toString()
      ..userName = username
      ..faction = faction
      ..country = country
      ..requestChannel = "Torn PDA v$appVersion";

    var bodyOut = wtfReviveModelToJson(modelOut);

    try {
      var response = await http.post(
        Uri.parse('https://port203.de/wtfapi/revive'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: bodyOut,
      );

      return [response.statusCode.toString(), json.decode(response.body)["message"]];
    } catch (e) {
      log(e.toString());
    }
    return ["Error", "There was an error contacting WTF, please contact them for more information!"];
  }
}
