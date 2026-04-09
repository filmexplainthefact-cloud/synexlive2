import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/chat_model.dart';
import '../utils/app_theme.dart';
import 'user_avatar.dart';

class ChatBubble extends StatelessWidget {
  final ChatModel chat;
  final bool isMe;
  const ChatBubble({super.key, required this.chat, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            UserAvatar(name: chat.userName, photoUrl: chat.userPhotoUrl, size: 26),
            const SizedBox(width: 6),
          ],
          Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Row(children: [
                    Text(chat.userName,
                      style: const TextStyle(color: AppTheme.textSec, fontSize: 10, fontWeight: FontWeight.w600)),
                    if (chat.isHost) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: AppTheme.gold, borderRadius: BorderRadius.circular(4)),
                        child: const Text('HOST', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w800))),
                    ],
                  ]),
                ),
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.62),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: isMe ? AppTheme.primary : AppTheme.card2,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14), topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(isMe ? 14 : 3),
                    bottomRight: Radius.circular(isMe ? 3 : 14)),
                ),
                child: Text(chat.message,
                  style: TextStyle(color: isMe ? Colors.white : AppTheme.textPri, fontSize: 13)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                child: Text(timeago.format(chat.timestamp),
                  style: const TextStyle(color: AppTheme.textSec, fontSize: 9)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
