import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:typed_data'; // Para Uint8List

part 'question_answer.freezed.dart';

@freezed
class QuestionAnswer with _$QuestionAnswer {
  const factory QuestionAnswer({
    required String question,
    required StringBuffer answer,
    Uint8List? image, // Añadir el campo opcional para la imagen
  }) = _QuestionAnswer;
}
