import 'dart:collection';

import 'package:likeminds_chat_fl/likeminds_chat_fl.dart';
import 'package:likeminds_chat_ss_fl/src/utils/tagging/helpers/tagging_helper.dart';

List<Conversation>? addTimeStampInConversationList(
    List<Conversation>? conversationList, int communityId) {
  if (conversationList == null) {
    return conversationList;
  }
  LinkedHashMap<String, List<Conversation>> mappedConversations =
      LinkedHashMap<String, List<Conversation>>();

  for (Conversation conversation in conversationList) {
    if (conversation.isTimeStamp == null || !conversation.isTimeStamp!) {
      if (mappedConversations.containsKey(conversation.date)) {
        mappedConversations[conversation.date]!.add(conversation);
      } else {
        mappedConversations[conversation.date!] = <Conversation>[conversation];
      }
    }
  }
  List<Conversation> conversationListWithTimeStamp = <Conversation>[];
  mappedConversations.forEach(
    (key, value) {
      conversationListWithTimeStamp.addAll(value);
      conversationListWithTimeStamp.add(
        Conversation(
          isTimeStamp: true,
          answer: key,
          communityId: communityId,
          chatroomId: 0,
          createdAt: key,
          header: key,
          id: 0,
          pollAnswerText: key,
        ),
      );
    },
  );
  return conversationListWithTimeStamp;
}

/// Helps us handle the state message addition to the list locally on
/// new chatroom topic selection by creating it using the [User] and [Conversation]
/// params - [User] loggedInUser, [Conversation] newTopic
Conversation conversationToLocalTopicStateMessage(
    User loggedInUser, Conversation newTopic) {
  Conversation stateMessage;
  String mockBackendMessage = newTopic.answer.isNotEmpty
      ? "${loggedInUser.name} changed current topic to ${TaggingHelper.extractStateMessage(newTopic.answer)}"
      : "${loggedInUser.name} set a media message as current topic";
  stateMessage = Conversation(
    answer: mockBackendMessage,
    createdAt: DateTime.now().millisecondsSinceEpoch.toString(),
    header: null,
    id: 0,
    state: 1,
  );
  return stateMessage;
}
