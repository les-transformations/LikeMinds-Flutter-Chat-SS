// GoRouter configuration
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:likeminds_chat_ss_fl/src/bloc/chatroom/chatroom_bloc.dart';
import 'package:likeminds_chat_ss_fl/src/bloc/chatroom_action/chatroom_action_bloc.dart';
import 'package:likeminds_chat_ss_fl/src/bloc/conversation_action/conversation_action_bloc.dart';
import 'package:likeminds_chat_ss_fl/src/bloc/participants/participants_bloc.dart';
import 'package:likeminds_chat_ss_fl/src/service/media_service.dart';
import 'package:likeminds_chat_ss_fl/src/utils/constants/ui_constants.dart';
import 'package:likeminds_chat_ss_fl/src/views/chatroom_page.dart';
import 'package:likeminds_chat_ss_fl/src/views/chatroom_participants_page.dart';
import 'package:likeminds_chat_ss_fl/src/views/home_page.dart';
import 'package:likeminds_chat_ss_fl/src/views/media_forwarding.dart';
import 'package:likeminds_chat_ss_fl/src/views/media_preview.dart';
import 'package:go_router/go_router.dart';
import 'package:likeminds_chat_fl/likeminds_chat_fl.dart';

const startRoute = '/';
const homeRoute = '/home';
const chatRoute = '/chatroom/:id';
const participantsRoute = '/participants';
const exploreRoute = '/explore';
const profileRoute = '/profile';
const moderationRoute = '/moderation';
const mediaForwardRoute = '/media_forward/:chatroomId';
const mediaPreviewRoute = '/media_preview';

final router = GoRouter(
  routes: [
    GoRoute(
        path: startRoute,
        builder: (context, state) {
          return const HomePage();
        }),
    GoRoute(
        path: chatRoute,
        builder: (context, state) {
          return MultiBlocProvider(
            providers: [
              BlocProvider<ChatroomBloc>(
                create: (context) => ChatroomBloc()
                  ..add(
                    InitChatroomEvent((GetChatroomRequestBuilder()
                          ..chatroomId(
                              int.parse(state.pathParameters['id'] ?? "0")))
                        .build()),
                  ),
              ),
              BlocProvider<ConversationActionBloc>(
                create: (context) => ConversationActionBloc(),
              ),
              BlocProvider<ChatroomActionBloc>(
                create: (context) => ChatroomActionBloc(),
              ),
            ],
            child: ChatRoomPage(
              chatroomId: int.parse(state.pathParameters['id'] ?? "0"),
              // isRoot: state.queryParams['isRoot']?.toBoolean() ?? false,
            ),
          );
        }),
    // GoRoute(
    //   path: exploreRoute,
    //   builder: (context, state) => BlocProvider(
    //     create: (context) => ExploreBloc()..add(InitExploreEvent()),
    //     child: const ExplorePage(),
    //   ),
    // ),
    // GoRoute(
    //   path: profileRoute,
    //   builder: (context, state) => BlocProvider(
    //     create: (context) => ProfileBloc()..add(InitProfileEvent()),
    //     child: const ProfilePage(),
    //   ),
    // ),
    GoRoute(
      path: participantsRoute,
      builder: (context, state) => BlocProvider<ParticipantsBloc>(
        create: (context) => ParticipantsBloc(),
        child: ChatroomParticipantsPage(
          chatroom: state.extra as ChatRoom,
        ),
      ),
    ),
    GoRoute(
      path: mediaForwardRoute,
      name: "media_forward",
      builder: (context, state) => MediaForward(
        media: state.extra as List<Media>,
        chatroomId: int.parse(state.pathParameters['chatroomId']!),
      ),
    ),
    GoRoute(
      path: mediaPreviewRoute,
      name: "media_preview",
      builder: (context, state) => MediaPreview(
        conversationAttachments: (state.extra as List<dynamic>)[0],
        chatroom: (state.extra as List<dynamic>)[1],
        conversation: (state.extra as List<dynamic>)[2],
        userMeta: (state.extra as List<dynamic>)[3],
      ),
    ),
  ],
  errorBuilder: (context, state) => const Scaffold(
    backgroundColor: kPrimaryColor,
    body: Center(
      child: Text(
        "An error occurred\nTry again later",
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
        ),
      ),
    ),
  ),
);
