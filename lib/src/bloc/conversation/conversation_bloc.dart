import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:likeminds_chat_ss_fl/likeminds_chat_ss_fl.dart';
import 'package:likeminds_chat_ss_fl/src/service/likeminds_service.dart';
import 'package:likeminds_chat_ss_fl/src/service/media_service.dart';
import 'package:likeminds_chat_ss_fl/src/service/preference_service.dart';
import 'package:likeminds_chat_ss_fl/src/service/service_locator.dart';
import 'package:likeminds_chat_ss_fl/src/utils/media/media_helper.dart';
import 'package:likeminds_chat_ss_fl/src/utils/realtime/realtime.dart';
import 'package:likeminds_chat_fl/likeminds_chat_fl.dart';

part 'conversation_event.dart';
part 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  MediaService mediaService = MediaService(!isDebug);
  // final DatabaseReference realTime = LMRealtime.instance.chatroom();
  int? lastConversationId;

  ConversationBloc() : super(ConversationInitial()) {
    on<ConversationEvent>((event, emit) async {
      if (event is LoadConversations) {
        if (event.getConversationRequest.page > 1) {
          emit(ConversationPaginationLoading());
        } else {
          emit(ConversationLoading());
        } //Perform logic
        LMResponse response = await locator<LikeMindsService>()
            .getConversation(event.getConversationRequest);
        if (response.success) {
          GetConversationResponse conversationResponse = response.data;
          conversationResponse.conversationData!.forEach((element) {
            element.member = conversationResponse
                .userMeta?[element.userId ?? element.memberId];
          });
          conversationResponse.conversationData!.forEach((element) {
            String? replyId = element.replyId == null
                ? element.replyConversation?.toString()
                : element.replyId.toString();
            element.replyConversationObject =
                conversationResponse.conversationMeta?[replyId];
            element.replyConversationObject?.member =
                conversationResponse.userMeta?[
                    element.replyConversationObject?.userId ??
                        element.replyConversationObject?.memberId];
          });
          emit(
            ConversationLoaded(conversationResponse),
          );
        } else {
          emit(
            ConversationError(response.errorMessage!, ''),
          );
        }
      }
    });

    on<PostConversation>((event, emit) async {
      await mapPostConversationFunction(
        event,
        emit,
      );
    });
    on<PostMultiMediaConversation>(
      (event, emit) async {
        await mapPostMultiMediaConversation(
          event,
          emit,
        );
      },
    );
  }

  mapPostMultiMediaConversation(
    PostMultiMediaConversation event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      DateTime dateTime = DateTime.now();
      User user = locator<LMPreferenceService>().getUser()!;
      Conversation conversation = Conversation(
        answer: event.postConversationRequest.text,
        chatroomId: event.postConversationRequest.chatroomId,
        createdAt: "",
        header: "",
        date: "${dateTime.day} ${dateTime.month} ${dateTime.year}",
        replyId: event.postConversationRequest.replyId,
        attachmentCount: event.postConversationRequest.attachmentCount,
        hasFiles: event.postConversationRequest.hasFiles,
        member: user,
        temporaryId: event.postConversationRequest.temporaryId,
        id: 1,
        userId: user.id,
      );
      emit(
        MultiMediaConversationLoading(
          conversation,
          event.mediaFiles,
        ),
      );
      LMResponse<PostConversationResponse> response =
          await locator<LikeMindsService>().postConversation(
        event.postConversationRequest,
      );

      if (response.success) {
        PostConversationResponse postConversationResponse = response.data!;
        if (postConversationResponse.success) {
          List<Media> fileLink = [];
          int length = event.mediaFiles.length;
          for (int i = 0; i < length; i++) {
            Media media = event.mediaFiles[i];
            String? url = await mediaService.uploadFile(
              media.mediaFile!,
              event.postConversationRequest.chatroomId,
              postConversationResponse.conversation!.id,
            );
            String? thumbnailUrl;
            if (media.mediaType == MediaType.video) {
              // If the thumbnail file is not present in media object
              // then generate the thumbnail and upload it to the server
              if (media.thumbnailFile == null) {
                await getVideoThumbnail(media);
              }
              thumbnailUrl = await mediaService.uploadFile(
                media.thumbnailFile!,
                event.postConversationRequest.chatroomId,
                postConversationResponse.conversation!.id,
              );
            }

            if (url == null) {
              throw 'Error uploading file';
            } else {
              String attachmentType = mapMediaTypeToString(media.mediaType);
              PutMediaRequest putMediaRequest = (PutMediaRequestBuilder()
                    ..conversationId(postConversationResponse.conversation!.id)
                    ..filesCount(length)
                    ..index(i)
                    ..height(media.height)
                    ..width(media.width)
                    ..meta({
                      'size': media.size,
                      'number_of_page': media.pageCount,
                    })
                    ..type(attachmentType)
                    ..thumbnailUrl(thumbnailUrl)
                    ..url(url))
                  .build();
              LMResponse<PutMediaResponse> uploadFileResponse =
                  await locator<LikeMindsService>()
                      .putMultimedia(putMediaRequest);
              if (!uploadFileResponse.success) {
                emit(
                  MultiMediaConversationError(
                    uploadFileResponse.errorMessage!,
                    event.postConversationRequest.temporaryId,
                  ),
                );
              } else {
                if (!uploadFileResponse.data!.success) {
                  emit(
                    MultiMediaConversationError(
                      uploadFileResponse.data!.errorMessage!,
                      event.postConversationRequest.temporaryId,
                    ),
                  );
                } else {
                  Media mediaItem = Media.fromJson(putMediaRequest.toJson());
                  mediaItem.mediaFile = media.mediaFile;
                  mediaItem.thumbnailFile = media.thumbnailFile;
                  fileLink.add(mediaItem);
                }
              }
            }
          }
          lastConversationId = response.data!.conversation!.id;
          emit(
            MultiMediaConversationPosted(
              postConversationResponse,
              fileLink,
            ),
          );
        } else {
          emit(
            MultiMediaConversationError(
              postConversationResponse.errorMessage!,
              event.postConversationRequest.temporaryId,
            ),
          );
        }
      } else {
        emit(
          MultiMediaConversationError(
            response.errorMessage!,
            event.postConversationRequest.temporaryId,
          ),
        );
        return false;
      }
    } catch (e) {
      emit(
        ConversationError(
          "An error occurred",
          event.postConversationRequest.temporaryId,
        ),
      );
      return false;
    }
  }

  mapPostConversationFunction(
      PostConversation event, Emitter<ConversationState> emit) async {
    try {
      DateTime dateTime = DateTime.now();
      User user = locator<LMPreferenceService>().getUser()!;
      Conversation conversation = Conversation(
        answer: event.postConversationRequest.text,
        chatroomId: event.postConversationRequest.chatroomId,
        createdAt: "",
        header: "",
        date: "${dateTime.day} ${dateTime.month} ${dateTime.year}",
        replyId: event.postConversationRequest.replyId,
        attachmentCount: event.postConversationRequest.attachmentCount,
        replyConversationObject: event.repliedTo,
        hasFiles: event.postConversationRequest.hasFiles,
        member: user,
        temporaryId: event.postConversationRequest.temporaryId,
        id: 1,
      );
      emit(LocalConversation(conversation));
      LMResponse<PostConversationResponse> response =
          await locator<LikeMindsService>().postConversation(
        event.postConversationRequest,
      );

      if (response.success) {
        if (response.data!.success) {
          Conversation conversation = response.data!.conversation!;
          if (conversation.replyId != null ||
              conversation.replyConversation != null) {
            conversation.replyConversationObject = event.repliedTo;
          }
          emit(ConversationPosted(response.data!));
        } else {
          emit(
            ConversationError(
              response.data!.errorMessage!,
              event.postConversationRequest.temporaryId,
            ),
          );
          return false;
        }
      } else {
        emit(
          ConversationError(
            response.errorMessage!,
            event.postConversationRequest.temporaryId,
          ),
        );
        return false;
      }
    } catch (e) {
      emit(
        ConversationError(
          "An error occurred",
          event.postConversationRequest.temporaryId,
        ),
      );
      return false;
    }
  }
}
