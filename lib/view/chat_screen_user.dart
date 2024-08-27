import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chat_gpt_flutter/chat_gpt_flutter.dart';
import 'package:chatgpt/model/question_answer.dart';
import 'package:chatgpt/theme.dart';
import 'package:chatgpt/view/components/chatgpt_answer_widget.dart' as answer_widget;
import 'package:chatgpt/view/components/loading_widget.dart';
import 'package:chatgpt/view/components/text_input_widget.dart' as input_widget;
import 'package:chatgpt/view/components/user_question_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:shared_preferences/shared_preferences.dart'; // Importa el paquete

import 'login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuestionLimitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> canAskQuestion() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Usuario no autenticado");
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final data = userDoc.data();

    if (data == null) {
      return true;
    }

    final lastAskedTime = (data['lastAskedTime'] as Timestamp?)?.toDate();
    final questionCount = data['questionCount'] ?? 0;

    final now = DateTime.now();
    final timeDifference = now.difference(lastAskedTime ?? now);

    if (timeDifference.inHours >= 24) {
      // Resetea el contador si han pasado 24 horas
      await _firestore.collection('users').doc(user.uid).update({
        'questionCount': 0,
        'lastAskedTime': now,
      });
      return true;
    }

    if (questionCount >= 25) {
      return false;
    }

    return true;
  }

  Future<void> incrementQuestionCount() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Usuario no autenticado");
    }

    final userDoc = _firestore.collection('users').doc(user.uid);

    final currentData = await userDoc.get();
    if (currentData.exists) {
      final questionCount = currentData.data()?['questionCount'] ?? 0;

      await userDoc.update({
        'questionCount': questionCount + 1,
        'lastAskedTime': DateTime.now(),
      });
    } else {
      throw Exception("No se pudo obtener la información del usuario.");
    }
  }
}

class ChatScreenUser extends StatefulWidget {
  const ChatScreenUser({Key? key}) : super(key: key);

  @override
  State<ChatScreenUser> createState() => _ChatScreenUserState();
}

class _ChatScreenUserState extends State<ChatScreenUser> {
  String? answer;
  final loadingNotifier = ValueNotifier<bool>(false);
  final List<QuestionAnswer> questionAnswers = [];
  final questionLimitService = QuestionLimitService();

  int questionLimit = 25;
  int currentQuestionCount = 0;

  late ScrollController scrollController;
  late TextEditingController inputQuestionController;

  void _checkSessionValidity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Obtén los datos del usuario desde Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      if (userData != null) {
        final storedSessionToken = userData['sessionToken'];
        print("Stored sessionToken en Firestore: $storedSessionToken");

        // Obtén el token de sesión almacenado localmente
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? localSessionToken = prefs.getString('sessionToken');
        print("Local sessionToken: $localSessionToken");

        // Comparar el token de Firestore con el token local
        if (storedSessionToken != localSessionToken) {
          // Si los tokens no coinciden, cierra la sesión y redirige al login
          _showError("Tu sesión ha caducado. Se cerrará la sesión.");
          await FirebaseAuth.instance.signOut();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } else {
        _showError("No se pudieron obtener los datos del usuario.");
      }
    }
  }

  @override
  void initState() {
    inputQuestionController = TextEditingController();
    scrollController = ScrollController();
    _loadQuestionCount(); // Cargar el contador desde Firestore
    super.initState();
    _checkSessionValidity(); // Verificación al cargar la página

    // Verificación periódica cada minuto
    Timer.periodic(Duration(minutes: 1), (timer) {
      _checkSessionValidity();
    });

  }

  Future<void> _loadQuestionCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = userDoc.data();
      if (data != null) {
        setState(() {
          currentQuestionCount = data['questionCount'] ?? 0;
        });
      }
    }
  }

  @override
  void dispose() {
    inputQuestionController.dispose();
    loadingNotifier.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg500Color,
      appBar: AppBar(
        elevation: 1,
        shadowColor: Colors.white12,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "ChatTDP",
              style: kWhiteText.copyWith(
                fontSize: 20,
                fontWeight: kSemiBold,
              ),
            ),
            Row(
              children: [
                Icon(Icons.question_answer, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  "${questionLimit - currentQuestionCount} incidentes restantes",
                  style: kWhiteText.copyWith(
                    fontSize: 14,
                    fontWeight: kRegular,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: kBg300Color,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: buildChatList()),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: input_widget.TextInputWidget(
                textController: inputQuestionController,
                onSubmitted: _sendTextMessage,
                onImagePicked: _handleImagePicked,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Expanded buildChatList() {
    return Expanded(
      child: ListView.separated(
        controller: scrollController,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        itemCount: questionAnswers.length,
        itemBuilder: (BuildContext context, int index) {
          final question = questionAnswers[index].question;
          final answer = questionAnswers[index].answer;
          final image = questionAnswers[index].image;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              UserQuestionWidget(
                question: question,
                imageBytes: image,
              ),
              const SizedBox(height: 16),
              answer_widget.ChatGptAnswerWidget(
                answer: answer.toString().trim(),
              ),
            ],
          );
        },
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    });
  }

  void _sendTextMessage() {
    _checkSessionValidity(); // Verificar antes de enviar el mensaje
    _handleMessageSubmission();
  }

  void _handleImagePicked(XFile? image) {
    if (image != null) {
      _handleMessageSubmission(image: image);
    }
  }

  bool _isSubmitting = false;

  Future<void> _handleMessageSubmission({String? question, XFile? image}) async {
    if (_isSubmitting) return;
    _isSubmitting = true;

    final canAsk = await questionLimitService.canAskQuestion();
    if (!canAsk) {
      _showError('Has alcanzado el límite de preguntas permitidas. Intenta nuevamente más tarde.');
      _isSubmitting = false;
      return;
    }

    final text = question ?? inputQuestionController.text.trim();

    if (text.isEmpty && image == null) {
      _showError('Debes ingresar una pregunta o seleccionar una imagen.');
      _isSubmitting = false;
      return;
    }

    Uint8List? imageBytes;
    if (image != null) {
      imageBytes = await image.readAsBytes();
    }

    inputQuestionController.clear();
    loadingNotifier.value = true;

    setState(() {
      questionAnswers.add(
        QuestionAnswer(
          question: text.isEmpty ? '[Imagen]' : text,
          answer: StringBuffer(),
          image: imageBytes,
        ),
      );
    });

    final response = await _sendRequestToServer(text, image: image);
    loadingNotifier.value = false;

    if (response != null) {
      setState(() {
        questionAnswers.last.answer.clear();
        questionAnswers.last.answer.write(response);
        _scrollToBottom();
        currentQuestionCount++;
      });
    } else {
      setState(() {
        questionAnswers.last.answer.write("Error al obtener respuesta del servidor");
      });
    }

    await questionLimitService.incrementQuestionCount();
    _isSubmitting = false;
  }

  Future<String?> _sendRequestToServer(String question, {XFile? image}) async {
    const url = 'https://chattdp-service-gmpuppbwwq-uc.a.run.app/generate';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));

      request.fields['input'] = question.isEmpty ? '[Imagen sin texto]' : question;

      if (image != null) {
        if (kIsWeb) {
          var imageBytes = await image.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              imageBytes,
              filename: image.name,
            ),
          );
        } else {
          var imageFile = await http.MultipartFile.fromPath('image', image.path);
          request.files.add(imageFile);
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['output'];
      } else {
        _showError('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showError('Error: $e');
    }

    return null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
