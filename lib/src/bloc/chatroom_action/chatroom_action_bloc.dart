import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:likeminds_chat_ss_fl/src/service/likeminds_service.dart';
import 'package:likeminds_chat_ss_fl/src/service/service_locator.dart';
import 'package:likeminds_chat_fl/likeminds_chat_fl.dart';
import 'package:meta/meta.dart';

part 'chatroom_action_event.dart';
part 'chatroom_action_state.dart';

class ChatroomActionBloc
    extends Bloc<ChatroomActionEvent, ChatroomActionState> {
  ChatroomActionBloc() : super(ChatroomActionInitial()) {
    on<ChatroomActionEvent>((event, emit) async {
      if (event is MarkReadChatroomEvent) {
        // ignore: unused_local_variable
        LMResponse response = await locator<LikeMindsService>()
            .markReadChatroom((MarkReadChatroomRequestBuilder()
                  ..chatroomId(event.chatroomId))
                .build());
      } else if (event is SetChatroomTopicEvent) {
        try {
          emit(ChatroomActionLoading());
          LMResponse<SetChatroomTopicResponse> response =
              await locator<LikeMindsService>()
                  .setChatroomTopic((SetChatroomTopicRequestBuilder()
                        ..chatroomId(event.chatroomId)
                        ..conversationId(event.conversationId))
                      .build());
          if (response.success) {
            if (response.data!.success) {
              emit(ChatroomTopicSet(event.topic));
            } else {
              emit(ChatroomTopicError(
                  errorMessage: response.data!.errorMessage!));
            }
          } else {
            emit(ChatroomTopicError(errorMessage: response.errorMessage!));
          }
        } catch (e) {
          emit(ChatroomTopicError(
              errorMessage: "An error occurred while setting topic"));
        }
      }
    });
  }
}
