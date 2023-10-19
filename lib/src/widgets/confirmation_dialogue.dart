import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:likeminds_chat_ss_fl/src/utils/constants/constants.dart';
import 'package:likeminds_chat_ui_fl/likeminds_chat_ui_fl.dart';

class LMConfirmationDialogue extends StatelessWidget {
  const LMConfirmationDialogue({
    super.key,
    this.height,
    this.width,
    required this.titleText,
    required this.bodyText,
    required this.onCancel,
    required this.onDelete,
  });

  final double? height;
  final double? width;
  final String titleText;
  final String bodyText;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? CupertinoAlertDialog(
            title: LMTextView(
              text: titleText,
              textAlign: TextAlign.center,
              textStyle: const TextStyle(
                fontSize: kFontMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: LMTextView(
              text: bodyText,
              textAlign: TextAlign.center,
              textStyle: const TextStyle(
                fontSize: kFontSmallMed,
              ),
            ),
            actions: [
              LMTextButton(
                height: 44,
                text: const LMTextView(
                  text: "Cancel",
                  textStyle: TextStyle(
                    color: kPrimaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: (value) {
                  onCancel.call();
                },
              ),
              LMTextButton(
                height: 44,
                text: const LMTextView(
                  text: "Delete",
                  textStyle: TextStyle(
                    color: kRedColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: (value) {
                  onDelete.call();
                },
              ),
            ],
          )
        : Dialog(
            surfaceTintColor: kWhiteColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            elevation: 6,
            child: SizedBox(
              width: width,
              height: height,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        LMTextView(
                          text: titleText,
                          textStyle: const TextStyle(
                            fontSize: kFontMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        LMIconButton(
                            icon: const LMIcon(
                              type: LMIconType.icon,
                              icon: Icons.close,
                              color: kGrey3Color,
                              size: 20,
                            ),
                            onTap: (value) {
                              onCancel.call();
                            })
                      ],
                    ),
                  ),
                  const Divider(
                    height: 0,
                    color: kGrey4Color,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    child: LMTextView(
                      text: bodyText,
                      textStyle: const TextStyle(
                        fontSize: kFontSmallMed,
                      ),
                    ),
                  ),
                  const Divider(
                    height: 0,
                    color: kGrey4Color,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: onCancel,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: kWhiteColor,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                width: 2,
                                color: Color(0xFF94A3B8),
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const LMTextView(
                            text: "Cancel",
                          ),
                        ),
                        kHorizontalPaddingMedium,
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: kRedColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onPressed: onDelete,
                          child: const LMTextView(
                            text: "Delete",
                            textStyle: TextStyle(color: kWhiteColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
