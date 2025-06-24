import 'package:flutter/material.dart';
import 'package:local_ai_chat/Screens/chat_page.dart';
// import 'package:local_ai_chat/Screens/manage_models.dart';
import 'package:local_ai_chat/Screens/model_download.dart';
import 'package:local_ai_chat/Screens/settings_page.dart';
import 'package:local_ai_chat/Screens/talk_page.dart';

class Hamburger extends StatelessWidget {
  const Hamburger({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.primary,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'A.I.R.I',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 20,
                        // fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'AI, Real-time, In-App',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 12,
                        // fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.mark_chat_unread_outlined,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Chat with AI'),
              onTap: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (BuildContext context) {
                  return const ChatPage();
                }));
              },
            ),
            ListTile(
              leading: Icon(
                Icons.mic_none_outlined,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Talk to AI'),
              onTap: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (BuildContext context) {
                  return const TalkPage();
                }));
              },
            ),
            ListTile(
              leading: Icon(
                Icons.model_training,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Manage Models'),
              onTap: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (BuildContext context) {
                  return const ModelCheckPage();
                }));
              },
            ),
            ListTile(
              leading: Icon(
                Icons.settings_outlined,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (BuildContext context) {
                  return const SettingsPage();
                }));
              },
            ),
          ],
        ),
      ),
    );
  }
}
