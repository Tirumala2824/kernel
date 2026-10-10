import 'package:flutter/material.dart';

/// Developer harness for the local_llm plugin. W1 adds model status,
/// import and a generation check here.
void main() => runApp(
  const MaterialApp(
    home: Scaffold(body: Center(child: Text('local_llm developer harness'))),
  ),
);
