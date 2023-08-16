import 'package:flutter/material.dart';
import 'package:likeminds_chat_ss_fl/src/bloc/home/home_bloc.dart';
import 'package:likeminds_chat_ss_fl/src/navigation/router.dart';
import 'package:likeminds_chat_ss_fl/src/service/media_service.dart';
import 'package:likeminds_chat_ss_fl/src/service/preference_service.dart';
import 'package:likeminds_chat_ss_fl/src/service/service_locator.dart';
import 'package:likeminds_chat_ss_fl/src/utils/constants/ui_constants.dart';
import 'package:likeminds_chat_ss_fl/src/utils/imports.dart';
import 'package:likeminds_chat_ss_fl/src/utils/media/media_helper.dart';
import 'package:likeminds_chat_ss_fl/src/utils/realtime/realtime.dart';
import 'package:likeminds_chat_ss_fl/src/utils/tagging/helpers/tagging_helper.dart';
import 'package:likeminds_chat_ss_fl/src/widgets/skeleton_list.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:likeminds_chat_fl/likeminds_chat_fl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:likeminds_chat_ui_fl/likeminds_chat_ui_fl.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // String? communityName;
  final int pageSize = 50;
  String? userName;
  User? user;
  HomeBloc? homeBloc;
  ValueNotifier<bool> rebuildPagedList = ValueNotifier(false);
  PagingController<int, LMListItem> homeFeedPagingController =
      PagingController(firstPageKey: 1);

  int _pageKey = 1;

  @override
  void initState() {
    super.initState();
    userName = locator<LMPreferenceService>().getUser()!.name;
    homeBloc = BlocProvider.of<HomeBloc>(context);
    homeBloc!.add(
      InitHomeEvent(page: _pageKey, pageSize: pageSize),
    );
    _addPaginationListener();
  }

  _addPaginationListener() {
    homeFeedPagingController.addPageRequestListener(
      (pageKey) {
        homeBloc!.add(
          InitHomeEvent(page: pageKey, pageSize: pageSize),
        );
      },
    );
  }

  updatePagingControllers(HomeState state) {
    if (state is HomeLoaded) {
      List<LMListItem> chatItems = getChats(context, state.response);
      _pageKey++;
      if (state.response.chatroomsData == null ||
          state.response.chatroomsData!.isEmpty ||
          state.response.chatroomsData!.length < pageSize) {
        homeFeedPagingController.appendLastPage(chatItems);
      } else {
        homeFeedPagingController.appendPage(chatItems, _pageKey);
      }
    } else if (state is UpdateHomeFeed) {
      List<LMListItem> chatItems = getChats(context, state.response);
      _pageKey = 2;
      homeFeedPagingController.itemList?.clear();
      homeFeedPagingController.nextPageKey = _pageKey;
      homeFeedPagingController.itemList = chatItems;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        router.pop();
        return Future.value(false);
      },
      child: Scaffold(
        body: Column(
          children: [
            SizedBox(
              width: 100.w,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 1.h,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      LMTextView(
                        text: "Chats",
                        textStyle:
                            Theme.of(context).textTheme.headlineSmall!.copyWith(
                                  color: kBlackColor,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      //   communityName ??
                      // ),
                      LMProfilePicture(
                        fallbackText: userName ?? "..",
                        size: 36,
                        imageUrl: user?.imageUrl,
                        backgroundColor: kSecondaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Divider(),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 1.h),
                child: BlocConsumer<HomeBloc, HomeState>(
                  bloc: homeBloc,
                  listener: (context, state) {
                    updatePagingControllers(state);
                  },
                  buildWhen: (previous, current) {
                    if (previous is HomeLoaded && current is HomeLoading) {
                      return false;
                    } else if (previous is UpdateHomeFeed &&
                        current is HomeLoading) {
                      return false;
                    }
                    return true;
                  },
                  builder: (context, state) {
                    if (state is HomeLoading) {
                      return const SkeletonChatRoomList();
                    } else if (state is HomeError) {
                      return Center(
                        child: Text(state.message),
                      );
                    } else if (state is HomeLoaded ||
                        state is UpdateHomeFeed ||
                        state is UpdatedHomeFeed) {
                      return SafeArea(
                        top: false,
                        child: ValueListenableBuilder(
                            valueListenable: rebuildPagedList,
                            builder: (context, _, __) {
                              return PagedListView<int, LMListItem>(
                                pagingController: homeFeedPagingController,
                                padding: EdgeInsets.zero,
                                physics: const ClampingScrollPhysics(),
                                builderDelegate:
                                    PagedChildBuilderDelegate<LMListItem>(
                                  newPageProgressIndicatorBuilder: (_) =>
                                      const SizedBox(),
                                  noItemsFoundIndicatorBuilder: (context) =>
                                      const SizedBox(),
                                  itemBuilder: (context, item, index) {
                                    return item;
                                  },
                                ),
                              );
                            }),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<LMListItem> getChats(
      BuildContext context, GetHomeFeedResponse response) {
    List<LMListItem> chats = [];
    final List<ChatRoom> chatrooms = response.chatroomsData ?? [];
    final Map<String, Conversation> lastConversations =
        response.conversationMeta ?? {};
    final Map<int, User> userMeta = response.userMeta ?? {};
    final Map<dynamic, dynamic>? attachmentDynamic =
        response.conversationAttachmentsMeta;

    for (int i = 0; i < chatrooms.length; i++) {
      final Conversation conversation =
          lastConversations[chatrooms[i].lastConversationId.toString()]!;
      final User user =
          userMeta[conversation.member?.id ?? conversation.userId]!;
      final List<dynamic>? attachment =
          attachmentDynamic?[conversation.id.toString()];

      final List<Media>? attachmentMeta =
          attachment?.map((e) => Media.fromJson(e)).toList();
      String _message = conversation.deletedByUserId == null
          ? '${user.name}: ${conversation.state != 0 ? TaggingHelper.extractStateMessage(
              conversation.answer,
            ) : TaggingHelper.convertRouteToTag(
              conversation.answer,
              withTilde: false,
            )}'
          : conversation.deletedByUserId == conversation.userId
              ? conversation.userId == user.id
                  ? 'You deleted this message'
                  : "This message was deleted"
              : "This message was deleted by the CM";
      chats.add(
        LMListItem(
          // chatroom: chatrooms[i],
          onTap: () {
            LMRealtime.instance.chatroomId = chatrooms[i].id;
            router.push("/chatroom/${chatrooms[i].id}");
          },
          avatar: LMProfilePicture(
            fallbackText: chatrooms[i].header,
            size: 12.w,
            imageUrl: chatrooms[i].chatroomImageUrl,
            backgroundColor: kSecondaryColor,
          ),
          title: LMTextView(
            text: chatrooms[i].header.isEmpty
                ? "NOT PRODUCING"
                : chatrooms[i].header,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: ((conversation.hasFiles ?? false) &&
                  conversation.deletedByUserId == null)
              ? getChatItemAttachmentTile(
                  attachmentMeta ?? <Media>[], conversation)
              : LMTextView(
                  text: conversation.state != 0
                      ? TaggingHelper.extractStateMessage(_message)
                      : _message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              LMTextView(
                text: getTime(conversation.createdEpoch!.toString()),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 6),
              Visibility(
                visible: chatrooms[i].unseenCount! > 0,
                child: Center(
                  child: LMTextView(
                    text: chatrooms[i].unseenCount! > 99
                        ? "99+"
                        : chatrooms[i].unseenCount.toString(),
                    textStyle: const TextStyle(
                      color: kWhiteColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    backgroundColor: kPrimaryColor,
                    borderRadius: 32,
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // user: userMeta[conversation.member?.id ?? conversation.userId],
        ),
      );
    }

    return chats;
  }

  String getTime(String time) {
    final int _time = int.tryParse(time) ?? 0;
    final DateTime now = DateTime.now();
    final DateTime messageTime = DateTime.fromMillisecondsSinceEpoch(_time);
    final Duration difference = now.difference(messageTime);
    if (difference.inDays > 0) {
      return DateFormat('dd/MM/yyyy').format(messageTime);
    }
    return DateFormat('kk:mm').format(messageTime);
  }

  // String getAttachmentText(AttachmentMeta? attachmentMeta, ) {
  //   if (attachmentMeta != null &&
  //       attachmentMeta?.first.mediaType == MediaType.document) {
  //     return "${conversation!.attachmentCount} ${conversation!.attachmentCount! > 1 ? "Documents" : "Document"}";
  //   } else if (attachmentMeta != null &&
  //       attachmentMeta?.first.mediaType == MediaType.video) {
  //     return "${conversation!.attachmentCount} ${conversation!.attachmentCount! > 1 ? "Videos" : "Video"}";
  //   } else {
  //     return "${conversation!.attachmentCount} ${conversation!.attachmentCount! > 1 ? "Images" : "Image"}";
  //   }
  // }

  // IconData getAttachmentIcon() {
  //   if (attachmentMeta != null &&
  //       attachmentMeta?.first.mediaType == MediaType.document) {
  //     return Icons.insert_drive_file;
  //   } else if (attachmentMeta != null &&
  //       attachmentMeta?.first.mediaType == MediaType.video) {
  //     return Icons.video_camera_back;
  //   }
  //   return Icons.camera_alt;
  // }
}

Widget getShimmer() => Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade300,
      period: const Duration(seconds: 2),
      direction: ShimmerDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: 12,
        ),
        child: Container(
          height: 16,
          width: 32.w,
          color: kWhiteColor,
        ),
      ),
    );
