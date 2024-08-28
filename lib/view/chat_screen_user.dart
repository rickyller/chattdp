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
import '../services/incident_service.dart';

class ChatScreenUser extends StatefulWidget {
  const ChatScreenUser({Key? key}) : super(key: key);

  @override
  State<ChatScreenUser> createState() => _ChatScreenUserState();
}

class _ChatScreenUserState extends State<ChatScreenUser> {
  String? answer;
  final loadingNotifier = ValueNotifier<bool>(false);
  final List<QuestionAnswer> questionAnswers = [];
  final incidentService = IncidentService(); // Usando IncidentService

  int questionLimit = 10; // Esto ahora puede depender del tipo de suscripción
  int currentQuestionCount = 0;

  late ScrollController scrollController;
  late TextEditingController inputQuestionController;

  void _checkSessionValidity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      if (userData != null) {
        final storedSessionToken = userData['sessionToken'];
        print("Stored sessionToken en Firestore: $storedSessionToken");

        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? localSessionToken = prefs.getString('sessionToken');
        print("Local sessionToken: $localSessionToken");

        if (storedSessionToken != null && storedSessionToken.isNotEmpty && storedSessionToken == localSessionToken) {
          // La sesión es válida
          print("La sesión es válida.");
        } else {
          // La sesión no es válida
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
    super.initState();
    inputQuestionController = TextEditingController();
    scrollController = ScrollController();

    // Configura un listener para el documento del usuario
    _setupIncidentCountListener();

    _checkSessionValidity();

    Timer.periodic(Duration(minutes: 1), (timer) {
      _checkSessionValidity();
    });
  }

  void _setupIncidentCountListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((documentSnapshot) {
        final data = documentSnapshot.data();
        if (data != null) {
          setState(() {
            currentQuestionCount = data['incidentCount'] ?? 0;
            final subscriptionType = data['subscriptionType'] ?? 'free';
            questionLimit = subscriptionType == 'premium' ? 100 : 10;
          });
        }
      });
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

  void _sendTextMessage() async {
    try {
      // Verificar si la sesión es válida antes de proceder
      _checkSessionValidity();

      // Usar IncidentService para verificar si el usuario puede realizar un incidente
      bool canAsk = await incidentService.canPerformIncident();
      if (!canAsk) {
        _showError('Has alcanzado el límite de incidentes permitidos o el máximo de dispositivos permitidos.');
        return;
      }

      // Si la verificación es exitosa, proceder a manejar el envío del mensaje
      _handleMessageSubmission();
    } catch (e) {
      _showError('Error al manejar la solicitud: $e');
    }
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

    try {
      bool canAsk = await incidentService.canPerformIncident();
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

      await incidentService.incrementIncidentCount();
    } catch (e) {
      _showError('Error al manejar la solicitud: $e');
    } finally {
      _isSubmitting = false;
    }
  }


  Future<String?> _sendRequestToServer(String question, {XFile? image}) async {
    const url = 'https://chattdp-service-gmpuppbwwq-uc.a.run.app/generate';

    try {
      var request = http.MultipartRequest('POST', Uri.parse
(url));

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
