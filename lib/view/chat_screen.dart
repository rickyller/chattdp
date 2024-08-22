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

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? answer;
  final loadingNotifier = ValueNotifier<bool>(false);
  final List<QuestionAnswer> questionAnswers = [];

  late ScrollController scrollController;
  late TextEditingController inputQuestionController;

  @override
  void initState() {
    inputQuestionController = TextEditingController();
    scrollController = ScrollController();
    super.initState();
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
        centerTitle: true,
        title: Text(
          "ChatTDP",
          style: kWhiteText.copyWith(fontSize: 20, fontWeight: kSemiBold),
        ),
        backgroundColor: kBg300Color,
      ),
      body: SafeArea(
        child: Column(
          children: [
            buildChatList(),
            input_widget.TextInputWidget(
              textController: inputQuestionController,
              onSubmitted: _sendTextMessage,
              onImagePicked: _handleImagePicked,
            )
          ],
        ),
      ),
    );
  }

  Expanded buildChatList() {
    return Expanded(
      child: ListView.separated(
        controller: scrollController,
        separatorBuilder: (context, index) => const SizedBox(
          height: 12,
        ),
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16, top: 16),
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
    _handleMessageSubmission();
  }

  void _handleImagePicked(XFile? image) {
    if (image != null) {
      _handleMessageSubmission(image: image);
    }
  }

  bool _isSubmitting = false;

  Future<void> _handleMessageSubmission({String? question, XFile? image}) async {
    if (_isSubmitting) return; // Salir si ya se está procesando un envío
    _isSubmitting = true;

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
      });
    } else {
      setState(() {
        questionAnswers.last.answer.write("Error al obtener respuesta del servidor");
      });
    }

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
