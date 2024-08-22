import 'dart:typed_data';
import 'package:chatgpt/theme.dart';
import 'package:flutter/material.dart';

class UserQuestionWidget extends StatelessWidget {
  final String question;
  final Uint8List? imageBytes;

  const UserQuestionWidget({
    required this.question,
    this.imageBytes,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (imageBytes != null) ...[
                Container(
                  margin: const EdgeInsets.only(left: 12, bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8), // Bordes redondeados para la imagen
                    child: Image.memory(
                      imageBytes!,
                      width: double.infinity, // O usa un valor como 200.0 para un ancho específico
                      fit: BoxFit.fitWidth, // Ajusta la imagen al ancho, manteniendo proporciones
                    ),

                  ),
                ),
              ],
              Container(
                padding: const EdgeInsets.all(8.0),
                margin: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  color: kBg100Color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  question,
                  style: kWhiteText.copyWith(fontSize: 16, fontWeight: kRegular),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ClipOval(
          child: Material(
            color: Colors.blueAccent,
            child: SizedBox(
              height: 32,
              width: 32,
              child: Center(
                child: Text(
                  "U",
                  style: kWhiteText.copyWith(
                    fontWeight: kSemiBold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
