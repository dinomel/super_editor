import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

class EditorNotifier extends ChangeNotifier {
  MutableDocument doc;
  ScrollController scrollController = ScrollController();
  int? dragIndex;
  String? dragNodeID;

  EditorNotifier({required this.doc});

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void onDragUpdate(
    DragUpdateDetails details,
    int Function(double) findComponentIndexAtOffset,
  ) {
    final newIndex = findComponentIndexAtOffset(
      details.globalPosition.dy + scrollController.offset,
    );
    if (dragIndex == newIndex || dragIndex == newIndex - 1) return;

    dragIndex = newIndex;
    dragNodeID = doc.getNodeAt(newIndex + 1)?.id;
    notifyListeners();
  }

  void onDragEnd(String nodeId) {
    if (dragIndex == null || dragIndex! < 0 || dragIndex! >= doc.nodes.length) {
      return;
    }
    final dragNodeIndex = doc.getNodeIndexById(nodeId) - 1;
    final dragNode = doc.getNodeAt(dragNodeIndex);
    if (dragNode == null) {
      log('dragNode is null!');
      return;
    }
    doc.moveNode(
      nodeId: nodeId,
      targetIndex: dragIndex! + 1,
    );
    doc.moveNode(
      nodeId: dragNode.id,
      targetIndex: dragIndex! + 1,
    );
    dragIndex = null;
    dragNodeID = null;
    notifyListeners();
  }

  bool isDragNodeVisible(String nodeId) => dragNodeID == nodeId;
}
