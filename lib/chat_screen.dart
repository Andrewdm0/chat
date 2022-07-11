import 'dart:io';
import 'package:chat/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

//Estado da classe
class _ChatScreenState extends State<ChatScreen> {

  final GoogleSignIn googleSignIn = GoogleSignIn();
  User? _currentUser;
  bool isLoading =  false;

  //Init State para pegar o usuario logado
  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  //Função para pegar o usuario
  Future<User?> _getUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    try {
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      final GoogleSignInAuthentication? googleSignInAuthentication =
          await googleSignInAccount?.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication?.idToken,
        accessToken: googleSignInAuthentication?.accessToken,
      );
      final UserCredential authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = authResult.user;
      return user;
    } catch (error) {
      print("ERROOOOOOOOOO -> $error");
    }
  }

  //Função para enviar as mensagens
  void _sendMessage({String? text, File? imgFile}) async {
    final User? user = await _getUser();

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Não foi possivel fazer o login tente novamente"),
          backgroundColor: Colors.red,
        ),
      );
    }

    Map<String, dynamic> data = {
      "uid": user?.uid,
      "senderName": user?.displayName,
      "senderPhotoUrl": user?.photoURL,
      "time": Timestamp.now(),
    };

    if (imgFile != null) {
      FirebaseStorage storage = FirebaseStorage.instance;
      String url;
      Reference ref =
          storage.ref().child(user!.uid + DateTime.now().millisecondsSinceEpoch.toString());
      UploadTask uploadTask = ref.putFile(imgFile);

      setState((){
        isLoading = true;
      });

      TaskSnapshot taskSnapshot = await uploadTask;
      url = await taskSnapshot.ref.getDownloadURL();
      data['imgUrl'] = url;

      setState((){
        isLoading = false;
      });

    }

    if (text != null) data['text'] = text;

    FirebaseFirestore.instance.collection("messages").add(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentUser != null
            ? 'Olá, ${_currentUser?.displayName}'
            : 'Chat app'),
        centerTitle: true,
        elevation: 0,
        actions: [
          _currentUser != null
              ? IconButton(
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                    googleSignIn.signOut();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Deslogado com sucesso."),
                      ),
                    );
                  },
                  icon: Icon(Icons.exit_to_app))
              : Container()
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection("messages").orderBy('time').snapshots(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  default:
                    List<DocumentSnapshot> documents =
                        snapshot.data!.docs.reversed.toList();

                    return ListView.builder(
                      itemCount: documents.length,
                      reverse: true,
                      itemBuilder: (context, index) {
                        print('-------------TAMANHO------------');
                        print(documents.length);
                        print('--------------------------------');
                        return ChatMessage(
                            data:
                                documents[index].data() as Map<String, dynamic>,
                            mine: documents[index]['uid'] == _currentUser?.uid);
                      },
                    );
                }
              },
            ),
          ),
          isLoading ? LinearProgressIndicator() : Container(),
          TextComposer(
            sendMessage: _sendMessage,
          ),
        ],
      ),
    );
  }
}
