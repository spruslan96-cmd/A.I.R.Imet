import 'package:flutter/material.dart';
import 'package:local_ai_chat/Screens/chat_page.dart';
import 'package:local_ai_chat/Screens/manage_models.dart';
import 'package:local_ai_chat/Screens/model_check_page.dart';
import 'package:local_ai_chat/Screens/talk_page.dart';

class Hamburger extends StatelessWidget {
  const Hamburger({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            child: Container(
              color: Colors.pink,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (BuildContext context) {
                return const ChatPage();
              }));
            },
            child: Text('Chat Page'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (BuildContext context) {
                return const TalkPage();
              }));
            },
            child: Text('Talk Page'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (BuildContext context) {
                return const ModelCheckPage();
              }));
            },
            child: Text('Model Page'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (BuildContext context) {
                return const ManageModelsPage();
              }));
            },
            child: Text('Model Manage'),
          ),
        ],
      ),
    );
  }
}
