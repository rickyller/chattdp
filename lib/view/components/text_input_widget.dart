import 'dart:io'; // Importar para manejar archivos locales
import 'package:chatgpt/theme.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // Importar para usar kIsWeb

class TextInputWidget extends StatefulWidget {
  final TextEditingController textController;
  final VoidCallback onSubmitted;
  final Function(XFile?) onImagePicked;

  const TextInputWidget(
      {required this.textController, required this.onSubmitted, required this.onImagePicked, Key? key})
      : super(key: key);

  @override
  _TextInputWidgetState createState() => _TextInputWidgetState();
}

class _TextInputWidgetState extends State<TextInputWidget> {
  XFile? _selectedImage;

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  void _sendMessage() {
    widget.onImagePicked(_selectedImage);
    widget.onSubmitted();
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(bottom: 12, left: 12),
            decoration: const BoxDecoration(
              color: kBg100Color,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(12),
                bottom: Radius.circular(12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedImage != null)
                  kIsWeb
                      ? Image.network(
                    _selectedImage!.path,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                      : Image.file(
                    File(_selectedImage!.path),
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                TextField(
                  controller: widget.textController,
                  minLines: 1,
                  maxLines: 1,
                  keyboardType: TextInputType.text,
                  style: kWhiteText.copyWith(fontSize: 16),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: kBg100Color,
                    hintText: 'Incidente:',
                    hintStyle: kWhiteText.copyWith(fontSize: 16),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(left: 12.0),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 48,
          height: 48,
          margin: const EdgeInsets.only(bottom: 12, right: 12),
          decoration: const BoxDecoration(
            color: kPrimaryColor,
            shape: BoxShape.circle,
          ),
          child: GestureDetector(
            onTap: _pickImage,
            child: const Icon(
              Iconsax.image,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 48,
          height: 48,
          margin: const EdgeInsets.only(bottom: 12, right: 12),
          decoration: const BoxDecoration(
            color: kPrimaryColor,
            shape: BoxShape.circle,
          ),
          child: GestureDetector(
            onTap: _sendMessage,
            child: const Icon(
              Icons.send,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
