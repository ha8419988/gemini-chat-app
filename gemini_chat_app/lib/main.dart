import 'dart:io';
import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:gemini_chat_app/constant.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  Gemini.init(apiKey: GEMINI_API_KEY);
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final Gemini gemini = Gemini.instance;
  ChatUser currentUser = ChatUser(
    id: '0',
    firstName: 'User',
  );
  ChatUser geminiUser = ChatUser(
    id: '1',
    firstName: 'Gemini',
    profileImage:
        'https://mir-s3-cdn-cf.behance.net/project_modules/fs/4843fb64294229.5c91200242a8c.jpg',
  );
  List<ChatMessage> messages = [];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          // colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Gemini Chat'),
        ),
        body: _buildUI(),
      ),
    );
  }

  _buildUI() {
    return DashChat(
      inputOptions: InputOptions(trailing: [
        IconButton(onPressed: _sendMediaMessage, icon: const Icon(Icons.image))
      ]),
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
    );
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });
    try {
      String question = chatMessage.text;
      List<Uint8List>? images;
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [
          File(chatMessage.medias!.first.url).readAsBytesSync(),
        ];
      }

      gemini
          .streamGenerateContent(
        question,
        images: images,
      )
          .listen((event) {
        ChatMessage? lastMessage = messages.firstOrNull;
        if (lastMessage != null && lastMessage.user == geminiUser) {
          lastMessage = messages.removeAt(0);
          String response = event.content?.parts?.fold(
                  '', (previous, current) => '$previous${current.text}') ??
              '';
          lastMessage.text += response;
          setState(() {
            messages = [lastMessage!, ...messages];
          });
        } else {
          String response = event.content?.parts?.fold(
                  '', (previous, current) => '$previous${current.text}') ??
              '';
          ChatMessage message = ChatMessage(
              user: geminiUser, createdAt: DateTime.now(), text: response);
          setState(() {
            messages = [message, ...messages];
          });
        }
      });
    } catch (e) {}
  }

  void _sendMediaMessage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? file = await imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (file != null) {
      ChatMessage message = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        // text: 'Describe this picture',
        medias: [
          ChatMedia(url: file.path, fileName: '', type: MediaType.image)
        ],
      );
      _sendMessage(message);
    }
  }
}
