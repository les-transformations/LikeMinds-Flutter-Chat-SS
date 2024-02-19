import 'package:carousel_slider/carousel_slider.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:likeminds_chat_ss_fl/src/bloc/conversation/conversation_bloc.dart';
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
  final TextEditingController textEditingController;
  final List<LMTagViewData> tags;
  const MediaForward({
    Key? key,
    required this.media,
    required this.chatroomId,
    required this.textEditingController,
    required this.tags,
  }) : super(key: key);

  @override
  State<MediaForward> createState() => _MediaForwardState();
}

class _MediaForwardState extends State<MediaForward> {
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
    tags = widget.tags;
    super.initState();
  }

  bool checkIfMultipleAttachments() {
    return mediaList.length > 1;
  }

  @override
  Widget build(BuildContext context) {
    mediaList = widget.media;

    chatActionBloc = ConversationBloc.instance;
    return Theme(
      data: kSuraasaThemeData,
      child: Scaffold(
        backgroundColor: kWhiteColor,
        appBar: AppBar(
          backgroundColor: kWhiteColor,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.close,
              color: kBlackColor,
            ),
          ),
          elevation: 0,
        ),
        body: ValueListenableBuilder(
            valueListenable: rebuildCurr,
            builder: (context, _, __) {
              return getMediaPreview();
            }),
        bottomSheet: BottomSheet(
          onClosing: () {},
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          builder: (context) => Padding(
            padding: EdgeInsets.only(
              bottom: 1.h,
              top: 1.h,
              left: 3.w,
              right: 3.w,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: 8.w,
                      maxHeight: 24.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kPaddingSmall,
                            ),
                            child: LMTextField(
                              isDown: false,
                              chatroomId: widget.chatroomId,
                              style: Theme.of(context).textTheme.bodyMedium!,
                              onChange: (value) {
                                // print(value);
                              },
                              onTagSelected: (tag) {
                                tags.add(tag);
                              },
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintMaxLines: 1,
                                hintStyle:
                                    Theme.of(context).textTheme.bodyMedium,
                                hintText: "Type something..",
                              ),
                              controller: widget.textEditingController,
                              focusNode: FocusNode(),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 3.w,
                          ),
                          child: SizedBox(
                            height: 4.h,
                            child: LMIconButton(
                              icon: const LMIcon(
                                type: LMIconType.svg,
                                assetPath: ssAttachmentIcon,
                              ),
                              onTap: (val) async {
                                if (await handlePermissions(1)) {
                                  MediaType mediaType = mediaList.isNotEmpty
                                      ? mediaList.first.mediaType
                                      : MediaType.photo;
                                  List<Media> pickedMediaFiles =
                                      mediaType == MediaType.document
                                          ? await pickDocumentFiles()
                                          : mediaType == MediaType.video
                                              ? await pickVideoFiles()
                                              : await pickImageFiles();
                                  if (pickedMediaFiles.isNotEmpty) {
                                    if (mediaList.length +
                                            pickedMediaFiles.length >
                                        10) {
                                      toast('Only 10 attachments can be sent');
                                      return;
                                    }
                                    for (Media media in pickedMediaFiles) {
                                      if (getFileSizeInDouble(media.size!) >
                                          100) {
                                        toast(
                                          'File size should be smaller than 100MB',
                                        );
                                        pickedMediaFiles.remove(media);
                                      }
                                    }
                                    mediaList.addAll(pickedMediaFiles);
                                  }
                                  rebuildCurr.value = !rebuildCurr.value;
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    final string = widget.textEditingController.text;
                    tags = TaggingHelper.matchTags(string, tags);
                    result = TaggingHelper.encodeString(string, tags);
                    result = result?.trim();
                    widget.textEditingController.clear();
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
          ),
        ),
      ),
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
      return Center(
        child: Column(
          children: [
            SizedBox(
              height: 2.h,
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 100.w, maxHeight: 60.h),
              child: Center(
                child: mediaList[currPosition].mediaType == MediaType.photo
                    ? Image.file(
                        mediaList[currPosition].mediaFile!,
                        fit: BoxFit.cover,
                      )
                    : Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 2.h,
                        ),
                        child: chatVideoFactory(
                            mediaList[currPosition], flickManager!),
                      ),
              ),
            ),
            const Spacer(),
            Container(
              decoration: const BoxDecoration(
                  color: kWhiteColor,
                  border: Border(
                    top: BorderSide(
                      color: kGreyColor,
                      width: 0.1,
                    ),
                  )),
              padding: EdgeInsets.only(
                left: 5.0,
                right: 5.0,
                top: 2.h,
                bottom: 12.h,
              ),
              child: checkIfMultipleAttachments()
                  ? SizedBox(
                      height: 15.w,
                      width: 100.w,
                      child: Center(
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
                      ),
                    )
                  : const SizedBox(),
            )
          ],
        ),
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
