import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget{
  const LoadingScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
            child: Column(
              spacing: 16,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                Text(message),
              ],
            ),
          );
  }
}