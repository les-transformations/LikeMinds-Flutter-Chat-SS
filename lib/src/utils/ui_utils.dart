import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:likeminds_chat_fl/likeminds_chat_fl.dart';

//Generic method for getting height
double getHeight(BuildContext context) {
  return MediaQuery.of(context).size.height;
}

//Generic method for getting width
double getWidth(BuildContext context) {
  return MediaQuery.of(context).size.width;
}

//Utils method for getting initials of a name (or first letter of every word)
String getInitials(String? name) {
  if (name == null || name == "") {
    return "";
  }
  try {
    List<String> parts = name.split(' '); // Split on whitespace
    if (parts.last.characters.first == "(") {
      // Check if last part is a parantheses
      parts.remove(parts.last); // Remove parantheses
    }
    var initials = parts.map((e) => e.characters.first);
    if (initials.length > 2) {
      initials = initials.toList().sublist(0, 2);
    }
    String initialString = initials
        .reduce((_, e) => _ + e) // Reduce into single string
        .toUpperCase(); // Capitalize
    return initialString;
  } catch (e) {
    return name[0].toUpperCase();
  }
}

extension StringColor on String {
  Color? toColor() {
    // if (primaryColor != null) {
    if (int.tryParse(this) != null) {
      return Color(int.tryParse(this)!);
    } else {
      return null;
    }
  }
}

extension StringToBool on String {
  bool toBoolean() {
    return (toLowerCase() == "true" || toLowerCase() == "1")
        ? true
        : (toLowerCase() == "false" || toLowerCase() == "0" ? false : false);
  }
}

String getTime(String time) {
  final int _time = int.tryParse(time) ?? 0;
  final DateTime now = DateTime.now();
  final DateTime messageTime = DateTime.fromMillisecondsSinceEpoch(_time);
  final Duration difference = now.difference(messageTime);
  if (difference.inDays > 0) {
    return DateFormat('dd/MM/yyyy').format(messageTime);
  }
  return DateFormat('kk:mm').format(messageTime);
}

class ConversationMessageState {
  static const int normal = 0;
  static const int firstMessage = 1;
  static const int memberJoinedOpenChatroom = 2;
  static const int memberLeftOpenChatroom = 3;
  static const int memberAddedToChatroom = 7;
  static const int memberLeftSecretChatroom = 8;
  static const int memberRemovedFromChatroom = 9;
  static const int poll = 10;
  static const int allMembersAdded = 11;
  static const int topicChanged = 12;
}

void filterOutStateMessage(List<Conversation> conversationList) {
  conversationList.removeWhere((element) {
    return element.state != null &&
        (element.state == ConversationMessageState.memberJoinedOpenChatroom ||
            element.state == ConversationMessageState.memberLeftOpenChatroom ||
            element.state ==
                ConversationMessageState.memberLeftSecretChatroom ||
            element.state == ConversationMessageState.poll);
  });
}

bool stateMessage(Conversation conversation) {
  if (conversation.state == ConversationMessageState.memberJoinedOpenChatroom ||
      conversation.state == ConversationMessageState.memberLeftOpenChatroom ||
      conversation.state == ConversationMessageState.memberLeftSecretChatroom ||
      conversation.state == ConversationMessageState.poll) {
    return false;
  } else {
    return true;
  }
}
