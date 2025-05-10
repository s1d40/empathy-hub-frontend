import 'package:empathy_hub_app/features/feed/presentation/models/post_model.dart'; // Changed import
import 'package:flutter/material.dart';

//Widget to displaty a single feed item

class FeedItemWidget extends StatelessWidget {
  final Post item; // Changed type to Post

  const FeedItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      elevation: 2.0,
      child: Padding(padding: const EdgeInsets.all(12.0), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundImage: item.avatarUrl != null
                  ? NetworkImage(item.avatarUrl!)
                  : null,
                radius: 20, //Handle null avatar
                child: item.avatarUrl == null
                  ? Text(item.username.isNotEmpty ? item.username[0].toUpperCase()  : '?')
                  : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      // Basic date formatting, consider using 'intl' package for better formatting
                      "${item.timestamp.toLocal().year}-${item.timestamp.toLocal().month.toString().padLeft(2, '0')}-${item.timestamp.toLocal().day.toString().padLeft(2, '0')} ${item.timestamp.toLocal().hour.toString().padLeft(2, '0')}:${item.timestamp.toLocal().minute.toString().padLeft(2, '0')}",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(item.content,
          style: const TextStyle(fontSize:15, height: 1.3),
          ),
        ],
      ),
    ));
    }
    }