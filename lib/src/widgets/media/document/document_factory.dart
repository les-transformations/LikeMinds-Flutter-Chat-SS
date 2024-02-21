import 'package:carousel_slider/carousel_slider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:likeminds_chat_ss_fl/src/bloc/conversation/conversation_bloc.dart';
import 'package:likeminds_chat_ss_fl/src/service/media_service.dart';
import 'package:likeminds_chat_ss_fl/src/utils/imports.dart';
import 'package:likeminds_chat_ss_fl/src/utils/media/media_helper.dart';
import 'package:likeminds_chat_ss_fl/src/utils/media/permission_handler.dart';
import 'package:likeminds_chat_ss_fl/src/utils/tagging/helpers/tagging_helper.dart';
import 'package:likeminds_chat_ss_fl/src/utils/tagging/tagging_textfield_ta.dart';
import 'package:likeminds_chat_fl/likeminds_chat_fl.dart';
import 'package:path/path.dart';

class DocumentFactory extends StatefulWidget {
  final List<Media> mediaList;
  final int chatroomId;
  const DocumentFactory(
      {Key? key, required this.mediaList, required this.chatroomId})
      : super(key: key);

  @override
  State<DocumentFactory> createState() => _DocumentFactoryState();
}

class _DocumentFactoryState extends State<DocumentFactory> {
  List<Media>? mediaList;
  final TextEditingController _textEditingController = TextEditingController();
  CarouselController controller = CarouselController();
  FilePicker filePicker = FilePicker.platform;
  ValueNotifier<bool> rebuildCurr = ValueNotifier<bool>(false);
  List<LMTagViewData> tags = [];
  String? result;
  int currPosition = 0;
  ConversationBloc? conversationBloc;

  bool checkIfMultipleAttachments() {
    return mediaList!.length > 1;
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    rebuildCurr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    conversationBloc = ConversationBloc.instance;
    mediaList = widget.mediaList;
    return ValueListenableBuilder(
      valueListenable: rebuildCurr,
      builder: (context, _, __) {
        return Column(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 100.w, maxHeight: 65.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  getDocumentThumbnail(
                    mediaList![currPosition].mediaFile!,
                    size: Size(100.w, 58.h),
                  ),
                  kVerticalPaddingXLarge,
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(
                        width: 80.w,
                        child: LMTextView(
                          text: basenameWithoutExtension(
                              mediaList![currPosition].mediaFile!.path),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          textStyle: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      kVerticalPaddingSmall,
                      getDocumentDetails(mediaList![currPosition]),
                    ],
                  ),
                ],
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
              child: Column(
                children: [
                  checkIfMultipleAttachments()
                      ? SizedBox(
                          height: 15.w,
                          width: 100.w,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: mediaList!.length,
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) => GestureDetector(
                              onTap: () {
                                currPosition = index;
                                rebuildCurr.value = !rebuildCurr.value;
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 6.0),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6.0),
                                    border: currPosition == index
                                        ? Border.all(
                                            color: secondary, width: 5.0)
                                        : null),
                                width: 15.w,
                                height: 15.w,
                                child: getDocumentThumbnail(
                                    mediaList![index].mediaFile!,
                                    size: Size(100.w, 58.h)),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
