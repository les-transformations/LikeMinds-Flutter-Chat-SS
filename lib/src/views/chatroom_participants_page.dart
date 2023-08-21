import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:likeminds_chat_ss_fl/src/bloc/participants/participants_bloc.dart';
import 'package:likeminds_chat_ss_fl/src/navigation/router.dart';
import 'package:likeminds_chat_ss_fl/src/utils/analytics/analytics.dart';
import 'package:likeminds_chat_ss_fl/src/utils/constants/ui_constants.dart';
import 'package:likeminds_chat_ss_fl/src/utils/imports.dart';
import 'package:likeminds_chat_ss_fl/src/utils/simple_bloc_observer.dart';
import 'package:likeminds_chat_ss_fl/src/utils/ui_utils.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:likeminds_chat_fl/likeminds_chat_fl.dart';
import 'package:likeminds_chat_ui_fl/likeminds_chat_ui_fl.dart';

class ChatroomParticipantsPage extends StatefulWidget {
  final ChatRoom chatroom;
  const ChatroomParticipantsPage({super.key, required this.chatroom});

  @override
  State<ChatroomParticipantsPage> createState() =>
      _ChatroomParticipantsPageState();
}

class _ChatroomParticipantsPageState extends State<ChatroomParticipantsPage> {
  ParticipantsBloc? participantsBloc;
  FocusNode focusNode = FocusNode();
  String? searchTerm;
  final ValueNotifier<bool> rebuildSearchBar = ValueNotifier<bool>(false);
  final TextEditingController _searchController = TextEditingController();
  final PagingController<int, User> _pagingController =
      PagingController(firstPageKey: 1);
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Bloc.observer = SimpleBlocObserver();
    participantsBloc = ParticipantsBloc();
    participantsBloc!.add(
      GetParticipants(
        getParticipantsRequest: (GetParticipantsRequestBuilder()
              ..chatroomId(widget.chatroom.id)
              ..page(1)
              ..pageSize(10)
              ..search(searchTerm)
              ..isSecret(widget.chatroom.isSecret ?? false))
            .build(),
      ),
    );
    _addPaginationListener();
  }

  @override
  void dispose() {
    participantsBloc?.close();
    focusNode.dispose();
    _searchController.dispose();
    rebuildSearchBar.dispose();
    _pagingController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  int _page = 1;

  _addPaginationListener() {
    _pagingController.addPageRequestListener((pageKey) {
      participantsBloc!.add(
        GetParticipants(
          getParticipantsRequest: (GetParticipantsRequestBuilder()
                ..chatroomId(widget.chatroom.id)
                ..page(pageKey)
                ..pageSize(10)
                ..search(searchTerm)
                ..isSecret(widget.chatroom.isSecret ?? false))
              .build(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        router.pop(context);
        return Future.value(false);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              ValueListenableBuilder(
                valueListenable: rebuildSearchBar,
                builder: (context, _, __) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        rebuildSearchBar.value
                            ? BackButton(
                                onPressed: () {
                                  router.pop(context);
                                },
                              )
                            : const SizedBox(),
                        rebuildSearchBar.value
                            ? kHorizontalPaddingXLarge
                            : const SizedBox(),
                        rebuildSearchBar.value
                            ? Expanded(
                                child: TextField(
                                  focusNode: focusNode,
                                  keyboardType: TextInputType.text,
                                  textCapitalization: TextCapitalization.words,
                                  controller: _searchController,
                                  onChanged: (value) {
                                    if (_debounce?.isActive ?? false) {
                                      _debounce?.cancel();
                                    }
                                    _debounce = Timer(
                                      const Duration(milliseconds: 500),
                                      () {
                                        searchTerm = value;
                                        _page = 1;
                                        _pagingController.nextPageKey = 2;
                                        _pagingController.itemList = <User>[];
                                        participantsBloc!.add(
                                          GetParticipants(
                                            getParticipantsRequest:
                                                (GetParticipantsRequestBuilder()
                                                      ..chatroomId(
                                                          widget.chatroom.id)
                                                      ..page(1)
                                                      ..pageSize(10)
                                                      ..search(searchTerm)
                                                      ..isSecret(widget.chatroom
                                                              .isSecret ??
                                                          false))
                                                    .build(),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Search...",
                                    hintStyle: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          color: kDarkGreyColor,
                                          fontSize: 12,
                                        ),
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const BackButton(),
                                  kHorizontalPaddingXLarge,
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const LMTextView(
                                        text: "Participants",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textStyle: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      kVerticalPaddingSmall,
                                      Text(
                                        "${widget.chatroom.participantCount ?? '--'} participants",
                                        style: const TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 32),
                                ],
                              ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            if (rebuildSearchBar.value) {
                              searchTerm = null;
                              _searchController.clear();
                              _page = 1;
                              _pagingController.nextPageKey = 2;
                              _pagingController.itemList = <User>[];
                              participantsBloc!.add(
                                GetParticipants(
                                  getParticipantsRequest:
                                      (GetParticipantsRequestBuilder()
                                            ..chatroomId(widget.chatroom.id)
                                            ..page(1)
                                            ..pageSize(10)
                                            ..search(searchTerm)
                                            ..isSecret(
                                                widget.chatroom.isSecret ??
                                                    false))
                                          .build(),
                                ),
                              );
                            } else {
                              if (focusNode.canRequestFocus) {
                                focusNode.requestFocus();
                              }
                            }
                            rebuildSearchBar.value = !rebuildSearchBar.value;
                          },
                          child: LMIcon(
                            type: LMIconType.icon,
                            icon: rebuildSearchBar.value
                                ? CupertinoIcons.xmark
                                : Icons.search,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Divider(),
              Expanded(
                child: BlocConsumer(
                    bloc: participantsBloc,
                    listener: (context, state) {
                      if (state is ParticipantsLoaded) {
                        _page++;
                        if (state
                            .getParticipantsResponse.participants!.isEmpty) {
                          _pagingController.appendLastPage(
                            state.getParticipantsResponse.participants!,
                          );
                        } else {
                          _pagingController.appendPage(
                            state.getParticipantsResponse.participants!,
                            _page,
                          );
                        }
                      } else if (state is ParticipantsError) {
                        _pagingController.error = state.message;
                      }
                    },
                    buildWhen: (prev, curr) {
                      if (curr is ParticipantsPaginationLoading) {
                        return false;
                      }
                      return true;
                    },
                    builder: (context, state) {
                      if (state is ParticipantsLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (state is ParticipantsLoaded) {
                        LMAnalytics.get()
                            .logEvent(AnalyticsKeys.viewChatroomParticipants, {
                          'chatroom_id': widget.chatroom.id,
                          'community_id': widget.chatroom.communityId,
                          'source': 'chatroom_overflow_menu',
                        });
                        return Column(
                          children: [
                            const SizedBox(height: 8),
                            Expanded(child: _buildParticipantsList()),
                          ],
                        );
                      } else if (state is ParticipantsError) {
                        return Center(
                          child: Text(state.message),
                        );
                      }
                      return const SizedBox();
                    }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantsList() {
    return PagedListView(
      padding: EdgeInsets.zero,
      pagingController: _pagingController,
      physics: const ClampingScrollPhysics(),
      builderDelegate: PagedChildBuilderDelegate<User>(
        itemBuilder: (context, item, index) {
          return ParticipantItem(
            participant: item,
          );
        },
      ),
    );
  }
}

class ParticipantItem extends StatelessWidget {
  final User participant;

  const ParticipantItem({super.key, required this.participant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (participant.sdkClientInfo != null &&
            participant.sdkClientInfo!.userUniqueId != null) {
          locator<LikeMindsService>().lmCallBack?.profileRouteCallback(
              lmUserId: participant.sdkClientInfo!.userUniqueId!);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: getWidth(context),
        height: 8.h,
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            LMProfilePicture(
              fallbackText: participant.name,
              imageUrl: participant.imageUrl,
              size: 48,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                participant.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
