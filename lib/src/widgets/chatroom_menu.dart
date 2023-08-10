import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:likeminds_chat_ss_fl/src/bloc/home/home_bloc.dart';
import 'package:likeminds_chat_ss_fl/src/navigation/router.dart';
import 'package:likeminds_chat_ss_fl/src/service/likeminds_service.dart';
import 'package:likeminds_chat_ss_fl/src/service/preference_service.dart';
import 'package:likeminds_chat_ss_fl/src/service/service_locator.dart';
import 'package:likeminds_chat_ss_fl/src/utils/constants/ui_constants.dart';
import 'package:likeminds_chat_ss_fl/src/utils/imports.dart';
import 'package:likeminds_chat_fl/likeminds_chat_fl.dart';
import 'package:likeminds_chat_ui_fl/likeminds_chat_ui_fl.dart';
import 'package:overlay_support/overlay_support.dart';

class ChatroomMenu extends StatefulWidget {
  final ChatRoom chatroom;
  final List<ChatroomAction> chatroomActions;

  const ChatroomMenu({
    Key? key,
    required this.chatroom,
    required this.chatroomActions,
  }) : super(key: key);

  @override
  State<ChatroomMenu> createState() => _ChatroomMenuState();
}

class _ChatroomMenuState extends State<ChatroomMenu> {
  CustomPopupMenuController? _controller;
  List<ChatroomAction>? chatroomActions;

  ValueNotifier<bool> rebuildChatroomMenu = ValueNotifier(false);

  HomeBloc? homeBloc;
  @override
  void initState() {
    super.initState();
    chatroomActions = widget.chatroomActions;
    _controller = CustomPopupMenuController();
  }

  @override
  Widget build(BuildContext context) {
    homeBloc = BlocProvider.of<HomeBloc>(context);
    return CustomPopupMenu(
      pressType: PressType.singleClick,
      showArrow: false,
      controller: _controller,
      enablePassEvent: false,
      menuBuilder: () => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: BoxConstraints(
            minWidth: 10.w,
            maxWidth: 52.w,
          ),
          color: Colors.white,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: chatroomActions?.length,
            itemBuilder: (BuildContext context, int index) {
              return getListTile(chatroomActions![index]);
            },
          ),
        ),
      ),
      child: const LMIcon(
        type: LMIconType.icon,
        icon: Icons.more_vert_rounded,
        size: 24,
        color: Colors.black,
      ),
    );
  }

  Widget? getListTile(ChatroomAction action) {
    return ListTile(
      onTap: () {
        performAction(action);
      },
      title: Text(
        action.title,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
      ),
    );
  }

  void performAction(ChatroomAction action) {
    switch (action.id) {
      case 2:
        // _controller.hideMenu();
        _controller!.hideMenu();
        router.push("/participants", extra: widget.chatroom);
        break;
      case 6:
        muteChatroom(action);
        break;
      case 8:
        muteChatroom(action);
        break;
      case 9:
        leaveChatroom();
        break;
      case 15:
        leaveChatroom();
        break;
      default:
        unimplemented();
    }
  }

  void unimplemented() {
    toast("Coming Soon");
  }

  void muteChatroom(ChatroomAction action) async {
    final response = await locator<LikeMindsService>()
        .muteChatroom((MuteChatroomRequestBuilder()
              ..chatroomId(widget.chatroom.id)
              ..value(!widget.chatroom.muteStatus!))
            .build());
    if (response.success) {
      // _controller.hideMenu();
      // rebuildChatroomMenu.value = !rebuildChatroomMenu.value;
      toast((action.title.toLowerCase() == "mute notifications")
          ? "Chatroom muted"
          : "Chatroom unmuted");
      chatroomActions = chatroomActions?.map((element) {
        if (element.title.toLowerCase() == "mute notifications") {
          element.title = "Unmute notifications";
        } else if (element.title.toLowerCase() == "unmute notifications") {
          element.title = "Mute notifications";
        }

        return element;
      }).toList();
      rebuildChatroomMenu.value = !rebuildChatroomMenu.value;
      _controller!.hideMenu();
      homeBloc!.add(UpdateHomeEvent());
    } else {
      toast(response.errorMessage!);
    }
  }

  void leaveChatroom() async {
    final User user = locator<LMPreferenceService>().getUser()!;
    if (!(widget.chatroom.isSecret ?? false)) {
      final response = await locator<LikeMindsService>()
          .followChatroom((FollowChatroomRequestBuilder()
                ..chatroomId(widget.chatroom.id)
                ..memberId(user.id)
                ..value(false))
              .build());
      if (response.success) {
        widget.chatroom.isGuest = true;
        // _controller.hideMenu();
        toast("Chatroom left");
        _controller!.hideMenu();
        homeBloc?.add(UpdateHomeEvent());
        router.pop();
      } else {
        toast(response.errorMessage!);
      }
    } else {
      final response = await locator<LikeMindsService>()
          .deleteParticipant((DeleteParticipantRequestBuilder()
                ..chatroomId(widget.chatroom.id)
                ..isSecret(true))
              .build());
      if (response.success) {
        widget.chatroom.isGuest = true;
        // _controller.hideMenu();
        toast("Chatroom left");
        _controller!.hideMenu();
        homeBloc?.add(UpdateHomeEvent());
        router.pop();
      } else {
        toast(response.errorMessage!);
      }
    }
    // final response =
    //     await locator<LikeMindsService>().leaveChatroom(LeaveChatroomRequest(
    //   chatroomId: chatroom.id,
    // ));
    // if (response.success) {
    //   toast("Chatroom left");
    // } else {
    //   toast(response.errorMessage!);
    // }
  }
}
