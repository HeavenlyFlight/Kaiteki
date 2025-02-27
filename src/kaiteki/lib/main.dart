import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kaiteki/account_manager.dart';
import 'package:kaiteki/app.dart';
import 'package:kaiteki/logger.dart';
import 'package:kaiteki/preferences/app_preferences.dart';
import 'package:kaiteki/preferences/preference_container.dart';
import 'package:kaiteki/repositories/account_secret_repository.dart';
import 'package:kaiteki/repositories/client_secret_repository.dart';
import 'package:kaiteki/repositories/secret_storages/shared_preferences_secret_storage.dart';
import 'package:kaiteki/theming/app_themes/default_app_themes.dart';
import 'package:kaiteki/theming/theme_container.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  var logger = getLogger('Kaiteki');

  // we need to run this to be able to get access to SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();

  var preferences = await SharedPreferences.getInstance();
  AppPreferences appPreferences;
  if (preferences.containsKey('preferences')) {
    var json = jsonDecode(preferences.getString('preferences')!);
    appPreferences = AppPreferences.fromJson(json);
  } else {
    appPreferences = AppPreferences();
  }

  var prefContainer = PreferenceContainer(appPreferences);

  var storage = SharedPreferencesSecureStorage(preferences);

  // fetch async resources e.g. user data
  var accountRepository = AccountSecretRepository(storage);
  var clientRepository = ClientSecretRepository(storage);

  try {
    await accountRepository.initialize();
    await clientRepository.initialize();
  } catch (e) {
    logger.e("Failed to initialize account and client secret repositories", e);
  }

  var accountContainer = AccountManager(
    accountRepository,
    clientRepository,
  );

  await accountContainer.loadAllAccounts();

  // FlutterLocalNotificationsPlugin? notificationsPlugin;
  //
  // try {
  //   notificationsPlugin = await initializeNotifications();
  // } catch (e) {
  //   logger.e("Failed to initialize notifications", e);
  // }

  // construct app
  var app = MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeContainer>(create: (BuildContext context) {
        return ThemeContainer(DefaultAppThemes.lightAppTheme);
      }),
      ChangeNotifierProvider.value(value: accountContainer),
      ChangeNotifierProvider.value(value: prefContainer),
    ],
    child: const KaitekiApp(),
  );

  // run.
  runApp(app);
}

Future<FlutterLocalNotificationsPlugin?> initializeNotifications() async {
  if (kIsWeb) return null;

  var plugin = FlutterLocalNotificationsPlugin();
  var initSettings = const InitializationSettings(
    android: AndroidInitializationSettings("@mipmap/ic_kaiteki"),
    iOS: IOSInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    ),
  );

  await plugin.initialize(initSettings);

  return plugin;
}
