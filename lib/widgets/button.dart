import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback voidCallback;
  const CustomButton({
    super.key,
    required this.text,
    required this.voidCallback,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        overlayColor: Color.fromARGB(255, 0, 191, 108),
        backgroundColor: Color.fromARGB(255, 2, 239, 159),
        minimumSize: Size(double.infinity, 50),
      ),
      onPressed: voidCallback,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 17.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
