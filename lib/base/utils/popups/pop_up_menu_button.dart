import 'package:flutter/material.dart';

class PopupButtonExample extends StatelessWidget {
  const PopupButtonExample({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stateless Bottom Sheet Example')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
          },
          child: const Text('Show Bottom Sheet1'),
        ),
      ),
    );
  }
}