// Flutter imports:
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Project imports:
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/providers/api_caller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class UserDetailsProvider extends ChangeNotifier {
  OwnProfileBasic basic;

  UserController _u = Get.put(UserController());

  void setUserDetails({@required OwnProfileBasic userDetails}) {
    basic = userDetails;
    _u.apiKey = basic.userApiKey;

    // If other keys are disabled
    // Ensure this does not happen in other setUserDetails calls (e.g. when reloading API key)
    if (!_u.alternativeYataKeyEnabled) {
      _u.alternativeYataKey = basic.userApiKey;
    }
    if (!_u.alternativeTornStatsKeyEnabled) {
      _u.alternativeTornStatsKey = basic.userApiKey;
    }

    Prefs().setOwnDetails(ownProfileBasicToJson(basic));
    notifyListeners();
  }

  void removeUser() {
    basic = OwnProfileBasic();
    Prefs().setOwnDetails('');
    notifyListeners();
  }

  Future<void> loadPreferences() async {
    // Initialize [myUser]. We will configure it in the next few lines.
    basic = OwnProfileBasic();

    var savedUser = await Prefs().getOwnDetails();
    // Check if we have an user at all (json is not empty)
    if (savedUser != '') {
      basic = ownProfileBasicFromJson(savedUser);

      // Set API key in the controller, in case API is down
      _u.apiKey = basic.userApiKey;

      bool alternativeYataKey = await Prefs().getAlternativeYataKeyEnabled();
      if (alternativeYataKey) {
        _u.alternativeYataKeyEnabled = true;
        _u.alternativeYataKey = await Prefs().getAlternativeYataKey();
      } else {
        _u.alternativeYataKey = basic.userApiKey;
      }

      bool alternativeTornStatsKey = await Prefs().getAlternativeTornStatsKeyEnabled();
      if (alternativeTornStatsKey) {
        _u.alternativeTornStatsKeyEnabled = true;
        _u.alternativeTornStatsKey = await Prefs().getAlternativeTornStatsKey();
      } else {
        _u.alternativeTornStatsKey = basic.userApiKey;
      }

      // Check if we have a valid API Key
      if (basic.userApiKeyValid) {
        // Call the API again to get the latest details (e.g. in case the
        // user has changed name or faction. Then save is as current user.
        // NOTE: calling basic to make things faster
        // Basic includes:
        // + Battle stats for TAC
        var apiVerify = await Get.find<ApiCallerController>().getOwnProfileBasic();

        if (apiVerify is OwnProfileBasic) {
          // Reassign from saved user, as these don't come with the API
          apiVerify.userApiKey = basic.userApiKey;
          apiVerify.userApiKeyValid = true;

          // Then recreate the basic model
          basic = apiVerify;

          Prefs().setOwnDetails(ownProfileBasicToJson(basic));
        }
      }
    }

    notifyListeners();
  }
}
