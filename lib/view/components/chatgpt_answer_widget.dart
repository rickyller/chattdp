import 'package:chatgpt/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatGptAnswerWidget extends StatelessWidget {
  final String answer;

  const ChatGptAnswerWidget({required this.answer, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipOval(
          child: SizedBox(
              height: 32,
              width: 32,
              child: Image.asset("assets/logotdp.png")),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(8.0),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: kBg100Color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    answer.toString().trim(),
                    style: kWhiteText.copyWith(
                        fontSize: 16, fontWeight: kRegular),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy, color: Colors.white, size: 20),
                  onPressed: () {
                    String keyword = "Descripción:";
                    int startIndex = answer.indexOf(keyword);
                    String textToCopy;

                    if (startIndex != -1) {
                      // Se encuentra la palabra clave y se copia el texto después de ella
                      textToCopy = answer.substring(startIndex + keyword.length).trim();
                    } else {
                      // Si la palabra clave no se encuentra, se copia todo el texto
                      textToCopy = answer;
                    }

                    Clipboard.setData(ClipboardData(text: textToCopy));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Texto copiado al portapapeles'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
