import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:likeminds_chat_ss_fl/src/bloc/conversation/conversation_bloc.dart';
import 'package:likeminds_chat_ss_fl/src/bloc/conversation_action/conversation_action_bloc.dart';
import 'package:likeminds_chat_ss_fl/src/navigation/router.dart';
import 'package:likeminds_chat_ss_fl/src/utils/analytics/analytics.dart';
import 'package:likeminds_chat_ss_fl/src/utils/constants/asset_constants.dart';
import 'package:likeminds_chat_ss_fl/src/utils/imports.dart';
import 'package:likeminds_chat_ss_fl/src/utils/media/media_helper.dart';
import 'package:likeminds_chat_ss_fl/src/utils/media/media_utils.dart';
import 'package:likeminds_chat_ss_fl/src/utils/media/permission_handler.dart';
import 'package:likeminds_chat_ss_fl/src/utils/member_rights/member_rights.dart';
import 'package:likeminds_chat_ss_fl/src/utils/simple_bloc_observer.dart';
import 'package:likeminds_chat_ss_fl/src/utils/tagging/helpers/tagging_helper.dart';
import 'package:likeminds_chat_ss_fl/src/utils/tagging/tagging_textfield_ta.dart';
import 'package:image_picker/image_picker.dart';
import 'package:likeminds_chat_fl/likeminds_chat_fl.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatBar extends StatefulWidget {
  final ChatRoom chatroom;
  final Conversation? replyToConversation;
  final List<Media>? replyConversationAttachments;
  final Conversation? editConversation;
  final Map<int, User?>? userMeta;
  final Function() scrollToBottom;

  const ChatBar({
    super.key,
    required this.chatroom,
    this.replyToConversation,
    this.replyConversationAttachments,
    this.editConversation,
    required this.scrollToBottom,
    this.userMeta,
  });

  @override
  State<ChatBar> createState() => _ChatBarState();
}

class _ChatBarState extends State<ChatBar> {
  ConversationActionBloc? chatActionBloc;
  ConversationBloc? conversationBloc;
  ImagePicker? imagePicker;
  FilePicker? filePicker;
  Conversation? replyToConversation;
  List<Media>? replyConversationAttachments;
  Conversation? editConversation;
  Map<int, User?>? userMeta;
  late CustomPopupMenuController _popupMenuController;
  late TextEditingController _textEditingController;
  late FocusNode _focusNode;
  User? currentUser = locator<LMPreferenceService>().getUser();
  MemberStateResponse? getMemberState =
      locator<LMPreferenceService>().getMemberRights();

  List<UserTag> userTags = [];
  String? result;

  ValueNotifier<bool> rebuildLinkPreview = ValueNotifier(false);
  String previewLink = '';
  MediaModel? linkModel;
  bool showLinkPreview =
      true; // if set to false link preview should not be displayed
  bool isActiveLink = true;
  Timer? _debounce;

  @override
  void initState() {
    Bloc.observer = SimpleBlocObserver();
    _popupMenuController = CustomPopupMenuController();
    _textEditingController = TextEditingController();
    _focusNode = FocusNode();
    imagePicker = ImagePicker();
    filePicker = FilePicker.platform;
    super.initState();
  }

  String getText() {
    if (_textEditingController.text.isNotEmpty) {
      return _textEditingController.text;
    } else {
      return "";
    }
  }

  @override
  void dispose() {
    _popupMenuController.dispose();
    _textEditingController.dispose();
    _focusNode.dispose();
    replyToConversation = null;
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged(String message) {
    // if (!showLinkPreview) return;
    isActiveLink = true;
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      handleTextLinks(message);
    });
  }

  Future<void> handleTextLinks(String text) async {
    String link = getFirstValidLinkFromString(text);
    if (link.isNotEmpty) {
      previewLink = link;
      DecodeUrlRequest request =
          (DecodeUrlRequestBuilder()..url(previewLink)).build();
      LMResponse<DecodeUrlResponse> response =
          await locator<LikeMindsService>().decodeUrl(request);
      if (response.success == true) {
        OgTags? responseTags = response.data!.ogTags;
        linkModel = MediaModel(
          mediaType: LMMediaType.link,
          link: previewLink,
          ogTags: OgTags(
            description: responseTags!.description,
            image: responseTags.image,
            title: responseTags.title,
            url: responseTags.url,
          ),
        );
        LMAnalytics.get().track(
          AnalyticsKeys.attachmentsUploaded,
          {
            'link': previewLink,
          },
        );
        showLinkPreview = true;
        rebuildLinkPreview.value = !rebuildLinkPreview.value;
      } else {
        linkModel = null;
        if (isActiveLink) {
          rebuildLinkPreview.value = !rebuildLinkPreview.value;
        }
      }
    } else if (link.isEmpty) {
      showLinkPreview = false;
      linkModel = null;
      rebuildLinkPreview.value = !rebuildLinkPreview.value;
    }
  }

  bool checkIfAnnouncementChannel() {
    if (getMemberState!.member!.state != 1 && widget.chatroom.type == 7) {
      return false;
    } else if (!MemberRightCheck.checkRespondRights(getMemberState)) {
      return false;
    } else {
      return true;
    }
  }

  String getChatBarHintText() {
    if (getMemberState!.member!.state != 1 && widget.chatroom.type == 7) {
      return 'Only Community Managers can respond here';
    } else if (!MemberRightCheck.checkRespondRights(getMemberState)) {
      return 'The community managers have restricted you from responding here';
    } else {
      return "Type something...";
    }
  }

  void setupEditText() {
    editConversation = widget.editConversation;
    String? convertedMsgText =
        TaggingHelper.convertRouteToTag(editConversation?.answer);
    if (widget.editConversation == null) {
      return;
    }
    _textEditingController.value =
        TextEditingValue(text: convertedMsgText ?? '');
    _textEditingController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textEditingController.text.length));
    userTags =
        TaggingHelper.addUserTagsIfMatched(editConversation?.answer ?? '');
    if (editConversation != null) {
      _focusNode.requestFocus();
    }
  }

  void setupReplyText() {
    replyToConversation = widget.replyToConversation;
    replyConversationAttachments = widget.replyConversationAttachments;
    if (replyToConversation != null) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    setupReplyText();
    setupEditText();
    userMeta = widget.userMeta;
    chatActionBloc = BlocProvider.of<ConversationActionBloc>(context);
    conversationBloc = BlocProvider.of<ConversationBloc>(context);
    return Column(
      children: [
        replyToConversation != null && checkIfAnnouncementChannel()
            ? _getReplyConversation()
            : const SizedBox(),
        editConversation != null && checkIfAnnouncementChannel()
            ? _getEditConversation()
            : const SizedBox(),
        ValueListenableBuilder(
            valueListenable: rebuildLinkPreview,
            builder: ((context, value, child) {
              return linkModel != null && showLinkPreview && isActiveLink
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Stack(
                        children: [
                          LMLinkPreview(
                            height: 120,
                            linkModel: linkModel,
                            backgroundColor: secondary.shade100,
                            showLinkUrl: false,
                            onTap: () {
                              launchUrl(
                                Uri.parse(linkModel?.ogTags?.url ?? ''),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                            border: Border.all(
                              width: 1,
                              color: secondary.shade100,
                            ),
                            title: LMTextView(
                              text: linkModel?.ogTags?.title ?? "--",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: kBlackColor,
                                height: 1.30,
                              ),
                            ),
                            subtitle: LMTextView(
                              text: linkModel?.ogTags?.description ?? "--",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textStyle: const TextStyle(
                                color: kBlackColor,
                                fontWeight: FontWeight.w400,
                                height: 1.30,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: () {
                                showLinkPreview = false;
                                linkModel = null;
                                rebuildLinkPreview.value =
                                    !rebuildLinkPreview.value;
                              },
                              child: const CloseButtonIcon(),
                            ),
                          )
                        ],
                      ),
                    )
                  : const SizedBox();
            })),
        Container(
          width: 100.w,
          color: kWhiteColor,
          padding: EdgeInsets.symmetric(
            horizontal: 3.w,
            vertical: 12,
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: checkIfAnnouncementChannel() ? 80.w : 90.w,
                  constraints: BoxConstraints(
                    // minHeight: 4.h,
                    minHeight: 8.w,
                    maxHeight: 24.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kPaddingSmall,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: LMTextField(
                            isDown: false,
                            chatroomId: widget.chatroom.id,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(fontSize: 14),
                            onTagSelected: (tag) {
                              debugPrint(tag.toString());
                              userTags.add(tag);
                              LMAnalytics.get()
                                  .logEvent(AnalyticsKeys.userTagsSomeone, {
                                'community_id': widget.chatroom.id,
                                'chatroom_name': widget.chatroom.title,
                                'tagged_user_id': tag.id,
                                'tagged_user_name': tag.name,
                              });
                            },
                            onChange: _onTextChanged,
                            controller: _textEditingController,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              enabled: checkIfAnnouncementChannel(),
                              hintMaxLines: 1,
                              hintStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(fontSize: 14),
                              hintText: getChatBarHintText(),
                            ),
                            focusNode: _focusNode,
                          ),
                        ),
                        checkIfAnnouncementChannel()
                            ? CustomPopupMenu(
                                controller: _popupMenuController,
                                enablePassEvent: false,
                                arrowColor: Colors.white,
                                showArrow: false,
                                menuBuilder: () => Container(
                                  margin: EdgeInsets.only(bottom: 1.h),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 100.w,
                                      // height: ,
                                      color: Colors.white,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 6.w,
                                          horizontal: 5.w,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                SizedBox(width: 12.w),
                                                LMIconButton(
                                                  onTap: (bool active) async {
                                                    _popupMenuController
                                                        .hideMenu();
                                                    try {
                                                      if (await handlePermissions(
                                                          1)) {
                                                        XFile? pickedImage =
                                                            await imagePicker!
                                                                .pickImage(
                                                                    source: ImageSource
                                                                        .camera);
                                                        List<Media> mediaList =
                                                            [];
                                                        if (pickedImage !=
                                                            null) {
                                                          File file = File(
                                                              pickedImage.path);
                                                          ui.Image image =
                                                              await decodeImageFromList(
                                                                  file.readAsBytesSync());
                                                          Media media = Media(
                                                            mediaType:
                                                                MediaType.photo,
                                                            height:
                                                                image.height,
                                                            width: image.width,
                                                            mediaFile: file,
                                                          );
                                                          mediaList.add(media);
                                                          if (mediaList
                                                              .isNotEmpty) {
                                                            router.pushNamed(
                                                              "media_forward",
                                                              extra: mediaList,
                                                              pathParameters: {
                                                                'chatroomId': widget
                                                                    .chatroom.id
                                                                    .toString()
                                                              },
                                                            );
                                                          }
                                                        }
                                                      }
                                                    } catch (e) {
                                                      toast(
                                                          'Something went wrong, try again');
                                                      return;
                                                    }
                                                  },
                                                  icon: const LMIcon(
                                                    type: LMIconType.svg,
                                                    assetPath: ssCameraIcon,
                                                    color: kWhiteColor,
                                                    size: 32,
                                                  ),
                                                  containerSize: 48,
                                                  borderRadius: 24,
                                                  backgroundColor:
                                                      const Color.fromRGBO(
                                                          229, 162, 86, 1),
                                                  title: LMTextView(
                                                    text: 'Camera',
                                                    textStyle: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium,
                                                  ),
                                                ),
                                                Spacer(),
                                                LMIconButton(
                                                  onTap: (bool isActive) async {
                                                    _popupMenuController
                                                        .hideMenu();
                                                    if (await handlePermissions(
                                                        2)) {
                                                      try {
                                                        List<Media>
                                                            pickedMediaFiles =
                                                            await pickImageFiles();
                                                        if (pickedMediaFiles
                                                                .length >
                                                            10) {
                                                          toast(
                                                              'Only 10 attachments can be sent');
                                                          return;
                                                        }

                                                        if (pickedMediaFiles
                                                            .isNotEmpty) {
                                                          for (Media mediaFile
                                                              in pickedMediaFiles) {
                                                            if (getFileSizeInDouble(
                                                                    mediaFile
                                                                        .size!) >
                                                                100) {
                                                              toast(
                                                                  'File size should be smaller than 100 MB');
                                                              pickedMediaFiles
                                                                  .remove(
                                                                      mediaFile);
                                                            }
                                                          }
                                                        }
                                                        if (pickedMediaFiles
                                                            .isNotEmpty) {
                                                          router.pushNamed(
                                                            "media_forward",
                                                            extra:
                                                                pickedMediaFiles,
                                                            pathParameters: {
                                                              'chatroomId':
                                                                  widget
                                                                      .chatroom
                                                                      .id
                                                                      .toString()
                                                            },
                                                          );
                                                        }
                                                      } catch (e) {
                                                        toast(
                                                            'Something went wrong, try again');
                                                        return;
                                                      }
                                                    }
                                                  },
                                                  icon: const LMIcon(
                                                    type: LMIconType.svg,
                                                    assetPath: ssGalleryIcon,
                                                    color: kWhiteColor,
                                                    size: 32,
                                                  ),
                                                  containerSize: 48,
                                                  borderRadius: 24,
                                                  backgroundColor:
                                                      const Color.fromRGBO(
                                                          154, 123, 186, 1),
                                                  title: LMTextView(
                                                    text: 'Image',
                                                    textStyle: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium,
                                                  ),
                                                ),
                                                Spacer(),
                                                LMIconButton(
                                                  onTap: (bool isActive) async {
                                                    _popupMenuController
                                                        .hideMenu();
                                                    if (await handlePermissions(
                                                        2)) {
                                                      try {
                                                        List<Media>
                                                            pickedMediaFiles =
                                                            await pickVideoFiles();
                                                        if (pickedMediaFiles
                                                                .length >
                                                            10) {
                                                          toast(
                                                              'Only 10 attachments can be sent');
                                                          return;
                                                        }

                                                        if (pickedMediaFiles
                                                            .isNotEmpty) {
                                                          for (Media mediaFile
                                                              in pickedMediaFiles) {
                                                            if (getFileSizeInDouble(
                                                                    mediaFile
                                                                        .size!) >
                                                                100) {
                                                              toast(
                                                                  'File size should be smaller than 100 MB');
                                                              pickedMediaFiles
                                                                  .remove(
                                                                      mediaFile);
                                                            }
                                                          }
                                                        }
                                                        if (pickedMediaFiles
                                                            .isNotEmpty) {
                                                          router.pushNamed(
                                                            "media_forward",
                                                            extra:
                                                                pickedMediaFiles,
                                                            pathParameters: {
                                                              'chatroomId':
                                                                  widget
                                                                      .chatroom
                                                                      .id
                                                                      .toString()
                                                            },
                                                          );
                                                        }
                                                      } catch (e) {
                                                        toast(
                                                            'Something went wrong, try again');
                                                        return;
                                                      }
                                                    }
                                                  },
                                                  icon: const LMIcon(
                                                    type: LMIconType.svg,
                                                    assetPath: ssVideoIcon,
                                                    color: kWhiteColor,
                                                    size: 24,
                                                  ),
                                                  containerSize: 48,
                                                  borderRadius: 24,
                                                  backgroundColor:
                                                      ui.Color.fromARGB(
                                                          255, 151, 188, 98),
                                                  title: LMTextView(
                                                    text: 'Video',
                                                    textStyle: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium,
                                                  ),
                                                ),
                                                SizedBox(width: 12.w),
                                              ],
                                            ),
                                            SizedBox(height: 2.h),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                SizedBox(width: 11.w),
                                                LMIconButton(
                                                  onTap: (bool active) async {
                                                    _popupMenuController
                                                        .hideMenu();
                                                    try {
                                                      if (await handlePermissions(
                                                          3)) {
                                                        List<Media>
                                                            pickedMediaFiles =
                                                            await pickDocumentFiles();
                                                        if (pickedMediaFiles
                                                            .isNotEmpty) {
                                                          router.pushNamed(
                                                            "media_forward",
                                                            extra:
                                                                pickedMediaFiles,
                                                            pathParameters: {
                                                              'chatroomId':
                                                                  widget
                                                                      .chatroom
                                                                      .id
                                                                      .toString()
                                                            },
                                                          );
                                                        }
                                                      }
                                                    } catch (e) {
                                                      toast(
                                                          'Something went wrong, try again');
                                                      return;
                                                    }
                                                  },
                                                  icon: const LMIcon(
                                                    type: LMIconType.svg,
                                                    assetPath: ssDocumentIcon,
                                                    color: kWhiteColor,
                                                    size: 32,
                                                  ),
                                                  containerSize: 48,
                                                  borderRadius: 24,
                                                  backgroundColor:
                                                      const Color.fromRGBO(
                                                          73, 183, 204, 1),
                                                  title: LMTextView(
                                                    text: 'Document',
                                                    textStyle: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium,
                                                  ),
                                                ),
                                                const Spacer(),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                pressType: PressType.singleClick,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 2.w,
                                    vertical: 3.w,
                                  ),
                                  child: const LMIcon(
                                    type: LMIconType.svg,
                                    assetPath: ssAttachmentIcon,
                                    size: 24,
                                  ),
                                ),
                              )
                            : const SizedBox(),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                checkIfAnnouncementChannel()
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: GestureDetector(
                          onTap: checkIfAnnouncementChannel()
                              ? () {
                                  if (_textEditingController.text.isEmpty) {
                                    toast("Text can't be empty");
                                  } else {
                                    final string = _textEditingController.text;
                                    userTags = TaggingHelper.matchTags(
                                        string, userTags);
                                    result = TaggingHelper.encodeString(
                                        string, userTags);
                                    result = result?.trim();
                                    if (editConversation != null) {
                                      linkModel = null;
                                      chatActionBloc!.add(EditConversation(
                                          (EditConversationRequestBuilder()
                                                ..conversationId(
                                                    editConversation!.id)
                                                ..text(result!))
                                              .build(),
                                          replyConversation: editConversation!
                                              .replyConversationObject));
                                      linkModel = null;
                                      isActiveLink = false;
                                      rebuildLinkPreview.value =
                                          !rebuildLinkPreview.value;
                                      if (!showLinkPreview) {
                                        showLinkPreview = true;
                                      }
                                      widget.scrollToBottom();
                                    } else {
                                      // Fluttertoast.showToast(msg: "Send message");
                                      if (isActiveLink &&
                                          showLinkPreview &&
                                          linkModel != null) {
                                        conversationBloc!.add(
                                            PostMultiMediaConversation(
                                                (PostConversationRequestBuilder()
                                                      ..chatroomId(
                                                          widget.chatroom.id)
                                                      ..temporaryId(DateTime
                                                              .now()
                                                          .millisecondsSinceEpoch
                                                          .toString())
                                                      ..text(result!)
                                                      ..replyId(
                                                          replyToConversation
                                                              ?.id)
                                                      ..ogTags(
                                                          linkModel!.ogTags!)
                                                      ..shareLink(linkModel!.link!))
                                                    .build(),
                                                [
                                              Media(
                                                  mediaType: MediaType.link,
                                                  ogTags: linkModel!.ogTags)
                                            ]));
                                        linkModel = null;
                                        isActiveLink = false;
                                        rebuildLinkPreview.value =
                                            !rebuildLinkPreview.value;
                                        if (!showLinkPreview) {
                                          showLinkPreview = true;
                                        }
                                        widget.scrollToBottom();
                                      } else {
                                        conversationBloc!.add(
                                          PostConversation(
                                              postConversationRequest:
                                                  (PostConversationRequestBuilder()
                                                        ..chatroomId(
                                                            widget.chatroom.id)
                                                        ..text(result!)
                                                        ..replyId(
                                                            replyToConversation
                                                                ?.id)
                                                        ..temporaryId(DateTime
                                                                .now()
                                                            .millisecondsSinceEpoch
                                                            .toString()))
                                                      .build(),
                                              repliedTo: replyToConversation),
                                        );
                                      }
                                      linkModel = null;
                                      isActiveLink = false;
                                      rebuildLinkPreview.value =
                                          !rebuildLinkPreview.value;
                                      if (!showLinkPreview) {
                                        showLinkPreview = true;
                                      }
                                      widget.scrollToBottom();
                                      if (replyToConversation != null) {
                                        LMAnalytics.get().track(
                                          AnalyticsKeys.messageReply,
                                          {
                                            "type": "text",
                                            "chatroom_id": widget.chatroom.id,
                                            "replied_to_member_id":
                                                replyToConversation?.member?.id,
                                            "replied_to_member_state":
                                                replyToConversation
                                                    ?.member?.state,
                                            "replied_to_message_id":
                                                replyToConversation?.id,
                                          },
                                        );
                                      }
                                    }
                                    if (widget.chatroom.isGuest ?? false) {
                                      toast("Chatroom joined");
                                      widget.chatroom.isGuest = false;
                                    }
                                    _textEditingController.clear();
                                    userTags = [];
                                    result = "";
                                    if (editConversation == null) {
                                      widget.scrollToBottom();
                                    }
                                    if (replyToConversation != null) {
                                      chatActionBloc!.add(ReplyRemove());
                                    }
                                    editConversation = null;
                                    replyToConversation = null;
                                  }
                                }
                              : () {},
                          child: Container(
                            height: 10.w,
                            width: 10.w,
                            decoration: BoxDecoration(
                              color: checkIfAnnouncementChannel()
                                  ? Colors.grey.shade200
                                  : kGreyColor,
                              borderRadius: BorderRadius.circular(6.w),
                              // boxShadow: [
                              //   BoxShadow(
                              //     offset: const Offset(0, 4),
                              //     blurRadius: 25,
                              //     color: kBlackColor.withOpacity(0.3),
                              //   )
                              // ]),
                            ),
                            child: const Center(
                              child: LMIcon(
                                type: LMIconType.svg,
                                assetPath: ssSendIcon,
                                color: kBlackColor,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Container _getReplyConversation() {
    if (replyToConversation == null) {
      return Container();
    }
    return Container(
      height: 10.h,
      width: 100.w,
      color: kGreyColor.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: LMReplyItem(
                  replyToConversation: replyToConversation,
                  borderRadius: 10,
                  backgroundColor:
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                  subtitle: replyToConversation != null
                      ? getChatItemAttachmentTile(
                          replyConversationAttachments ?? [],
                          replyToConversation!,
                        )
                      : null,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                chatActionBloc!.add(ReplyRemove());
              },
              icon: const Icon(
                Icons.close,
                color: kGreyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container _getEditConversation() {
    return Container(
      height: 8.h,
      width: 100.w,
      color: kGreyColor.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  color: kGreyColor.withOpacity(0.2),
                  child: Row(
                    children: [
                      Container(
                        width: 1.w,
                        color: primary,
                      ),
                      kHorizontalPaddingMedium,
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Edit message",
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          kVerticalPaddingSmall,
                          SizedBox(
                            width: 70.w,
                            child: Text(
                              TaggingHelper.convertRouteToTag(
                                  editConversation?.answer,
                                  withTilde: false)!,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                chatActionBloc!.add(EditRemove());
                _textEditingController.clear();
              },
              icon: const Icon(
                Icons.close,
                color: kGreyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
