import 'package:flutter/material.dart';

class TextFeildWidget extends StatefulWidget {
  final TextEditingController controller;
  final bool? isPasswordVisible;
  final String? Function(String?)? validator;
  final String hintText;
  final IconButton? iconbutton;
  final String? errorText;

  const TextFeildWidget({
    super.key,
    required this.controller,
    required this.hintText,
    required this.validator,
    this.isPasswordVisible,
    this.iconbutton,
    this.errorText,
  });

  @override
  State<TextFeildWidget> createState() => TextFeildWidgetState();
}

class TextFeildWidgetState extends State<TextFeildWidget> {
  // Border Style
  final OutlineInputBorder borderStyle = OutlineInputBorder(
    borderSide: const BorderSide(color: Colors.transparent),
    borderRadius: BorderRadius.circular(50),
  );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPasswordVisible ?? false,
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefix: const SizedBox(width: 10),
        suffixIcon: widget.iconbutton,
        hintStyle: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
        enabledBorder: borderStyle,
        focusedBorder: borderStyle,
        errorBorder: borderStyle,
        focusedErrorBorder: borderStyle,
        errorText: widget.errorText,
      ),
    );
  }
}
