import 'package:likeminds_chat_ss_fl/src/service/media_service.dart';
import 'package:likeminds_chat_ss_fl/src/utils/imports.dart';
import 'package:likeminds_chat_ss_fl/src/widgets/media/widget/document_tile.dart';

// ChatBubble for Single Document Attachment
Widget getSingleDocPreview(Media media) {
  return DocumentThumbnailFile(
    media: media,
  );
}

// ChatBubble for Two Document Attachment
Widget getDualDocPreview(List<Media> mediaList) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.start,
    children: <Widget>[
      DocumentTile(
        media: mediaList.first,
      ),
      DocumentTile(
        media: mediaList[1],
      )
    ],
  );
}

// ChatBubble for more than two Document Attachment

class GetMultipleDocPreview extends StatefulWidget {
  final List<Media> mediaList;
  const GetMultipleDocPreview({
    Key? key,
    required this.mediaList,
  }) : super(key: key);

  @override
  State<GetMultipleDocPreview> createState() => GgetMultipleDocPreviewState();
}

class GgetMultipleDocPreviewState extends State<GetMultipleDocPreview> {
  List<Media>? mediaList;
  ValueNotifier<bool> rebuildCurr = ValueNotifier<bool>(false);
  int length = 2;

  void onMoreButtonTap() {
    length = mediaList!.length;
    rebuildCurr.value = !rebuildCurr.value;
  }

  @override
  Widget build(BuildContext context) {
    mediaList = widget.mediaList;
    return ValueListenableBuilder(
      valueListenable: rebuildCurr,
      builder: (context, _, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: length,
              itemBuilder: (context, index) => DocumentTile(
                media: mediaList![index],
              ),
            ),
            mediaList!.length > 2 && mediaList!.length != length
                ? const SizedBox(height: 8)
                : const SizedBox(),
            mediaList!.length > 2 && mediaList!.length != length
                ? GestureDetector(
                    onTap: onMoreButtonTap,
                    behavior: HitTestBehavior.translucent,
                    child: SizedBox(
                      width: 72,
                      height: 24,
                      child: LMTextView(
                        text: '+ ${mediaList!.length - 2} more',
                        textStyle:
                            Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  color: secondary.shade800,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                  )
                : const SizedBox(),
          ],
        );
      },
    );
  }
}
