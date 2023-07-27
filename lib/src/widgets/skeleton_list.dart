import 'package:likeminds_chat_ss_fl/src/utils/imports.dart';
import 'package:likeminds_chat_ss_fl/src/widgets/skeleton_chat_box.dart';

class SkeletonChatRoomList extends StatelessWidget {
  const SkeletonChatRoomList({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      itemCount: 10,
      itemBuilder: (BuildContext context, int index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade300,
          period: const Duration(seconds: 2),
          direction: ShimmerDirection.ltr,
          child: const SkeletonChatBox(),
        );
      },
    );
  }
}
