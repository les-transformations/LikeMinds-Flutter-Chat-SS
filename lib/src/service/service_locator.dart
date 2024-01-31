import 'package:flutter/material.dart';
import 'package:likeminds_chat_ss_fl/src/service/likeminds_service.dart';
import 'package:likeminds_chat_ss_fl/src/service/navigation_service.dart';
import 'package:likeminds_chat_ss_fl/src/service/preference_service.dart';
import 'package:get_it/get_it.dart';
import 'package:likeminds_chat_fl/likeminds_chat_fl.dart';

final GetIt locator = GetIt.instance;

void setupChat({
  required String apiKey,
  LMSDKCallback? lmCallBack,
  required GlobalKey<NavigatorState> navigatorKey,
}) {
  if (!locator.isRegistered<NavigationService>()) {
    locator.registerSingleton(NavigationService(
      navigatorKey: navigatorKey,
    ));
  }
  locator.registerSingleton(LikeMindsService(
    apiKey: apiKey,
    lmCallBack: lmCallBack,
  ));
  locator.registerSingleton(LMPreferenceService());
}
