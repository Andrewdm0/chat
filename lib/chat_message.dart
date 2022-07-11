import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  const ChatMessage({Key? key, required this.data, required this.mine}) : super(key: key);

  final Map<String, dynamic> data;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      child: Row(
        children: [
          !mine?
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundImage: NetworkImage(data['senderPhotoUrl']),
            ),
          ): Container(),
          Expanded(
            child: Column(
              crossAxisAlignment: mine? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  data['senderName'],
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                data['imgUrl'] != null
                    ? Image.network(data['imgUrl'], width: 250,)
                    : Text(
                        data['text'],
                        textAlign: mine? TextAlign.end: TextAlign.start,
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
              ],
            ),
          ),
          mine?
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: CircleAvatar(
              backgroundImage: NetworkImage(data['senderPhotoUrl']),
            ),
          ): Container(),
        ],
      ),
    );
  }
}
