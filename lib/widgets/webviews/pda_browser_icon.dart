import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/torn-pda-native/auth/native_auth_provider.dart';

class PdaBrowserIcon extends StatelessWidget {
  const PdaBrowserIcon({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool automaticLogins = context.read<NativeAuthProvider>().tryAutomaticLogins;
    return GestureDetector(
      child: Image.asset(
        'images/icons/torn_pda_browser.png',
        width: 25,
      ),
      onTap: () {
        context.read<WebViewProvider>().pdaIconActivation(
              shortTap: true,
              automaticLogin: automaticLogins,
              context: context,
            );
      },
      onLongPress: () {
        context.read<WebViewProvider>().pdaIconActivation(
              shortTap: false,
              automaticLogin: automaticLogins,
              context: context,
            );
      },
    );
  }
}
