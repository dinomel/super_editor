import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

class ExampleEditorNotifier extends ChangeNotifier {
  MutableDocument doc;
  ScrollController scrollController = ScrollController();

  ExampleEditorNotifier({required this.doc});

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
