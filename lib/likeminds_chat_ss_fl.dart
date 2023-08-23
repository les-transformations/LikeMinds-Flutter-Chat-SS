import 'dart:io';

import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:likeminds_chat_fl/likeminds_chat_fl.dart';
import 'package:likeminds_chat_ss_fl/src/bloc/auth/auth_bloc.dart';
import 'package:likeminds_chat_ss_fl/src/bloc/chatroom/chatroom_bloc.dart';
import 'package:likeminds_chat_ss_fl/src/bloc/conversation/conversation_bloc.dart';
import 'package:likeminds_chat_ss_fl/src/bloc/home/home_bloc.dart';
import 'package:likeminds_chat_ss_fl/src/navigation/router.dart';
import 'package:likeminds_chat_ss_fl/src/utils/imports.dart';
import 'package:likeminds_chat_ss_fl/src/utils/lm_willpop.dart';
import 'package:likeminds_chat_ui_fl/likeminds_chat_ui_fl.dart';

import 'src/utils/credentials/firebase_credentials.dart';

export 'package:likeminds_chat_ss_fl/src/utils/notifications/notification_handler.dart';

const bool isDebug = bool.fromEnvironment('DEBUG');

class LMChat extends StatelessWidget {
  final String _userId;
  final String _userName;
  final String? _domain;
  final int? _defaultChatroom;
  final VoidCallback? _backButtonCallback;

  final AuthBloc _authBloc = AuthBloc();

  LMChat._internal(
    this._userId,
    this._userName,
    this._domain,
    this._defaultChatroom,
    this._backButtonCallback,
  ) {
    debugPrint('LMChat initialized');
    _authBloc.add(LoginEvent(
      userId: _userId,
      username: _userName,
    ));
  }

  static LMChat instance({required LMChatBuilder builder}) {
    if (builder.getUserId == null && builder.getUserName == null) {
      throw Exception(
        'LMChat builder needs to be initialized with User ID, or User Name',
      );
    } else {
      return LMChat._internal(
        builder.getUserId!,
        builder.getUserName!,
        builder.getDomain,
        builder.getDefaultChatroom,
        builder.getBackButtonCallback,
      );
    }
  }

  static void setupLMChat({
    required String apiKey,
    LMSDKCallback? lmCallBack,
  }) {
    setupChat(
      apiKey: apiKey,
      lmCallBack: lmCallBack,
    );
    initFirebase();
  }

  static void logout() {
    locator<LikeMindsService>().logout(LogoutRequestBuilder().build());
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    return LMCustomWillPop(
      onWillPop: true,
      backButtonCallback: _backButtonCallback,
      child: Scaffold(
        backgroundColor: kWhiteColor,
        body: Center(
          child: BlocConsumer<AuthBloc, AuthState>(
            bloc: _authBloc,
            listener: (context, state) {},
            builder: (context, state) {
              if (state is AuthSuccess) {
                return MultiBlocProvider(
                  providers: [
                    BlocProvider<HomeBloc>(
                      create: (context) => HomeBloc(),
                    ),
                    BlocProvider<ConversationBloc>(
                      create: (context) => ConversationBloc(),
                    ),
                    BlocProvider<ChatroomBloc>(
                      create: (context) => ChatroomBloc(),
                    )
                  ],
                  child: MaterialApp.router(
                    routerConfig: router,
                    debugShowCheckedModeBanner: isDebug,
                    theme: ThemeData(
                      colorScheme: ColorScheme.fromSeed(
                        seedColor: primary,
                        primary: primary,
                        secondary: secondary,
                      ),
                      pageTransitionsTheme: const PageTransitionsTheme(
                        builders: {
                          TargetPlatform.android: ZoomPageTransitionsBuilder(),
                          TargetPlatform.iOS: CupertinoWillPopScopePageTransionsBuilder(),
                        },
                      ),
                      useMaterial3: true,
                      fontFamily: 'Montserrat',
                      textTheme: const TextTheme(
                        displayLarge: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: kBlackColor,
                        ),
                        displayMedium: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: kBlackColor,
                        ),
                        displaySmall: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: kBlackColor,
                        ),
                        bodyLarge: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: kBlackColor,
                        ),
                        bodyMedium: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: kBlackColor,
                        ),
                        bodySmall: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: kBlackColor,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  color: kPrimaryColor,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

initFirebase() async {
  try {
    // final clientFirebase = Firebase.app();
    final ourFirebase = await Firebase.initializeApp(
      name: 'likeminds_chat',
      options: !isDebug
          ?
          //Prod Firebase options
          Platform.isIOS
              ? FirebaseOptions(
                  apiKey: FbCredsProd.fbApiKey,
                  appId: FbCredsProd.fbAppIdIOS,
                  messagingSenderId: FbCredsProd.fbMessagingSenderId,
                  projectId: FbCredsProd.fbProjectId,
                  databaseURL: FbCredsProd.fbDatabaseUrl,
                )
              : FirebaseOptions(
                  apiKey: FbCredsProd.fbApiKey,
                  appId: FbCredsProd.fbAppIdAN,
                  messagingSenderId: FbCredsProd.fbMessagingSenderId,
                  projectId: FbCredsProd.fbProjectId,
                  databaseURL: FbCredsProd.fbDatabaseUrl,
                )
          //Beta Firebase options
          : Platform.isIOS
              ? FirebaseOptions(
                  apiKey: FbCredsDev.fbApiKey,
                  appId: FbCredsDev.fbAppIdIOS,
                  messagingSenderId: FbCredsDev.fbMessagingSenderId,
                  projectId: FbCredsDev.fbProjectId,
                  databaseURL: FbCredsDev.fbDatabaseUrl,
                )
              : FirebaseOptions(
                  apiKey: FbCredsDev.fbApiKey,
                  appId: FbCredsDev.fbAppIdIOS,
                  messagingSenderId: FbCredsDev.fbMessagingSenderId,
                  projectId: FbCredsDev.fbProjectId,
                  databaseURL: FbCredsDev.fbDatabaseUrl,
                ),
    );
    // debugPrint("Client Firebase - ${clientFirebase.options.appId}");
    debugPrint("Our Firebase - ${ourFirebase.options.appId}");
  } on FirebaseException catch (e) {
    debugPrint("Make sure you have initialized firebase, ${e.toString()}");
  }
}

class LMChatBuilder {
  String? _userId;
  String? _userName;
  String? _domain;
  int? _defaultChatroom;

  // TEMP callback for a back button to manage exit
  // of chat instance gracefully.
  VoidCallback? _backButtonCallback;

  LMChatBuilder();

  void userId(String userId) => _userId = userId;
  void userName(String userName) => _userName = userName;
  void domain(String domain) => _domain = domain;
  void defaultChatroom(int? defaultChatroomId) => _defaultChatroom = defaultChatroomId;
  void backButtonCallback(VoidCallback? backButtonCallback) => _backButtonCallback = backButtonCallback;

  String? get getUserId => _userId;
  String? get getUserName => _userName;
  String? get getDomain => _domain;
  int? get getDefaultChatroom => _defaultChatroom;
  VoidCallback? get getBackButtonCallback => _backButtonCallback;
}
