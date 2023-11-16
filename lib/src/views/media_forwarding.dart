import 'package:carousel_slider/carousel_slider.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:likeminds_chat_ss_fl/src/bloc/conversation/conversation_bloc.dart';
import 'package:likeminds_chat_ss_fl/src/navigation/router.dart';
import 'package:likeminds_chat_ss_fl/src/service/media_service.dart';
import 'package:likeminds_chat_ss_fl/src/utils/constants/asset_constants.dart';
import 'package:likeminds_chat_ss_fl/src/utils/imports.dart';
import 'package:likeminds_chat_ss_fl/src/utils/media/media_helper.dart';
import 'package:likeminds_chat_ss_fl/src/utils/media/media_utils.dart';
import 'package:likeminds_chat_ss_fl/src/utils/media/permission_handler.dart';
import 'package:likeminds_chat_ss_fl/src/utils/tagging/helpers/tagging_helper.dart';
import 'package:likeminds_chat_ss_fl/src/utils/tagging/tagging_textfield_ta.dart';
import 'package:likeminds_chat_ss_fl/src/widgets/media/document/document_factory.dart';
import 'package:likeminds_chat_ss_fl/src/widgets/media/multimedia/video/chat_video_factory.dart';
import 'package:image_picker/image_picker.dart';
import 'package:likeminds_chat_fl/likeminds_chat_fl.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:video_player/video_player.dart';

class MediaForward extends StatefulWidget {
  final int chatroomId;
  final List<Media> media;
  const MediaForward({
    Key? key,
    required this.media,
    required this.chatroomId,
  }) : super(key: key);

  @override
  State<MediaForward> createState() => _MediaForwardState();
}

class _MediaForwardState extends State<MediaForward> {
  final TextEditingController _textEditingController = TextEditingController();
  ImagePicker imagePicker = ImagePicker();
  List<Media> mediaList = [];
  int currPosition = 0;
  CarouselController controller = CarouselController();
  ValueNotifier<bool> rebuildCurr = ValueNotifier<bool>(false);
  ConversationBloc? chatActionBloc;
  FlickManager? flickManager;

  List<LMTagViewData> tags = [];
  String? result;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _textEditingController.dispose();

    super.dispose();
  }

  bool checkIfMultipleAttachments() {
    return mediaList.length > 1;
  }

  @override
  Widget build(BuildContext context) {
    mediaList = widget.media;

    chatActionBloc = BlocProvider.of<ConversationBloc>(context);
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        leading: IconButton(
          onPressed: () {
            router.pop();
          },
          icon: const Icon(
            Icons.arrow_back,
          ),
        ),
        elevation: 0,
      ),
      body: ValueListenableBuilder(
          valueListenable: rebuildCurr,
          builder: (context, _, __) {
            return getMediaPreview();
          }),
    );
  }

  void setupFlickManager() {
    if (mediaList[currPosition].mediaType == MediaType.photo) {
      return;
    } else if (mediaList[currPosition].mediaType == MediaType.video &&
        flickManager == null) {
      flickManager = FlickManager(
        videoPlayerController:
            VideoPlayerController.file(mediaList[currPosition].mediaFile!),
        autoPlay: true,
        onVideoEnd: () {
          flickManager?.flickVideoManager?.videoPlayerController!
              .setLooping(true);
        },
        autoInitialize: true,
      );
    }
  }

  Widget getMediaPreview() {
    if (mediaList.first.mediaType == MediaType.photo ||
        mediaList.first.mediaType == MediaType.video) {
      // Initialise Flick Manager in case the selected media is an video
      setupFlickManager();
      return Column(
        children: [
          Expanded(
            child: mediaList[currPosition].mediaType == MediaType.photo
                ? AspectRatio(
                    aspectRatio: mediaList[currPosition].width! /
                        mediaList[currPosition].height!,
                    child: Image.file(mediaList[currPosition].mediaFile!),
                  )
                : chatVideoFactory(mediaList[currPosition], flickManager!),
          ),
          Container(
            decoration: const BoxDecoration(
                color: kWhiteColor,
                border: Border(
                  top: BorderSide(
                    color: kGreyColor,
                    width: 0.1,
                  ),
                )),
            padding: EdgeInsets.symmetric(
              horizontal: 5.0,
              vertical: 2.h,
            ),
            child: Column(
              children: [
                checkIfMultipleAttachments()
                    ? SizedBox(
                        height: 15.w,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: mediaList.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) => GestureDetector(
                            onTap: () {
                              currPosition = index;
                              if (mediaList[index].mediaType ==
                                  MediaType.video) {
                                if (flickManager == null) {
                                  flickManager = FlickManager(
                                    videoPlayerController:
                                        VideoPlayerController.file(
                                            mediaList[index].mediaFile!),
                                    autoPlay: true,
                                    onVideoEnd: () {
                                      flickManager?.flickVideoManager
                                          ?.videoPlayerController!
                                          .setLooping(true);
                                    },
                                    autoInitialize: true,
                                  );
                                } else {
                                  flickManager?.handleChangeVideo(
                                    VideoPlayerController.file(
                                        mediaList[index].mediaFile!),
                                  );
                                }
                              }
                              rebuildCurr.value = !rebuildCurr.value;
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 3.0,
                              ),
                              clipBehavior: Clip.hardEdge,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: currPosition == index
                                      ? Border.all(
                                          color: secondary.shade400,
                                          width: 4.0,
                                          // strokeAlign:
                                          //     BorderSide.strokeAlignOutside,
                                        )
                                      : null),
                              width: 15.w,
                              height: 15.w,
                              child: mediaList[index].mediaType ==
                                      MediaType.photo
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.file(
                                        mediaList[index].mediaFile!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  // check if thumbnail file is there in the media object
                                  // if not then get the thumbnail from the video file
                                  : mediaList[index].thumbnailFile != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: Image.file(
                                            mediaList[index].thumbnailFile!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: FutureBuilder(
                                            future: getVideoThumbnail(
                                                mediaList[index]),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return mediaShimmer();
                                              } else if (snapshot.data !=
                                                  null) {
                                                return Image.file(
                                                  snapshot.data!,
                                                  fit: BoxFit.cover,
                                                );
                                              } else {
                                                return SizedBox(
                                                  child: Icon(
                                                    Icons.error,
                                                    color: secondary.shade400,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(),
                SizedBox(height: 1.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () async {
                        if (await handlePermissions(1)) {
                          List<Media> pickedVideoFiles = await pickImageFiles();
                          if (pickedVideoFiles.isNotEmpty) {
                            if (mediaList.length + pickedVideoFiles.length >
                                10) {
                              toast('Only 10 attachments can be sent');
                              return;
                            }
                            for (Media media in pickedVideoFiles) {
                              if (getFileSizeInDouble(media.size!) > 100) {
                                toast(
                                  'File size should be smaller than 100MB',
                                );
                                pickedVideoFiles.remove(media);
                              }
                            }
                            mediaList.addAll(pickedVideoFiles);
                          }
                          rebuildCurr.value = !rebuildCurr.value;
                        }
                      },
                      child: SizedBox(
                        width: 10.w,
                        height: 10.w,
                        child: const LMIcon(
                          type: LMIconType.svg,
                          assetPath: ssGalleryIcon,
                          color: kGrey3Color,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
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
                          child: LMTextField(
                            isDown: false,
                            chatroomId: widget.chatroomId,
                            style: Theme.of(context).textTheme.bodyMedium!,
                            // onTagSelected: (tag) {
                            //   // print(tag);
                            //   userTags.add(tag);
                            // },
                            onChange: (value) {
                              // print(value);
                            },
                            onTagSelected: (tag) {
                              tags.add(tag);
                              // LMAnalytics.get()
                              //     .logEvent(AnalyticsKeys.userTagsSomeone, {
                              //   'community_id': widget.chatroom.id,
                              //   'chatroom_name': widget.chatroom.title,
                              //   'tagged_user_id': tag.id,
                              //   'tagged_user_name': tag.name,
                              // });
                            },
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintMaxLines: 1,
                              hintStyle: Theme.of(context).textTheme.bodyMedium,
                              hintText: "Type something..",
                            ),
                            controller: _textEditingController,
                            focusNode: FocusNode(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        router.pop();
                        final string = _textEditingController.text;
                        tags = TaggingHelper.matchTags(string, tags);
                        result = TaggingHelper.encodeString(string, tags);
                        result = result?.trim();
                        chatActionBloc!.add(
                          PostMultiMediaConversation(
                            (PostConversationRequestBuilder()
                                  ..attachmentCount(mediaList.length)
                                  ..chatroomId(widget.chatroomId)
                                  ..temporaryId(DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString())
                                  ..text(result!)
                                  ..hasFiles(true))
                                .build(),
                            mediaList,
                          ),
                        );
                      },
                      child: Container(
                        height: 10.w,
                        width: 10.w,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
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
                            type: LMIconType.icon,
                            icon: Icons.send_outlined,
                            color: kBlackColor,
                            size: 18,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(height: 1.h),
              ],
            ),
          )
        ],
      );
    } else if (mediaList.first.mediaType == MediaType.document) {
      return DocumentFactory(
        mediaList: mediaList,
        chatroomId: widget.chatroomId,
      );
    }
    return const SizedBox();
  }
}
