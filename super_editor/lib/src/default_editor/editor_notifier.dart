import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

class EditorNotifier extends ChangeNotifier {
  final bool editable;

  MutableDocument doc;
  ScrollController scrollController = ScrollController();
  int? dragIndex;
  String? dragNodeID;
  double? dragPositionDeltaY;
  Timer? dragAutoscrollTimer;
  double? screenHeight;
  final double topPadding;
  final autoscrollCoefficient = 8;

  bool isDragNodeVisible(String nodeId) => dragNodeID == nodeId;

  EditorNotifier({
    required this.doc,
    this.topPadding = 0,
    this.editable = true,
  });

  @override
  void dispose() {
    scrollController.dispose();
    dragAutoscrollTimer?.cancel();
    super.dispose();
  }

  void onDragUpdate({
    required BuildContext context,
    required DragUpdateDetails details,
    required int Function(double) findComponentIndexAtOffset,
    required String nodeId,
  }) {
    final mediaQuery = MediaQuery.of(Scaffold.of(context).context);
    screenHeight = MediaQuery.of(context).size.height -
        mediaQuery.viewInsets.bottom -
        topPadding;
    _setAutoscrollTimer();
    dragPositionDeltaY = details.globalPosition.dy - topPadding;
    final nodeIndex = doc.getNodeIndexById(nodeId);
    final newIndex = findComponentIndexAtOffset(
      details.globalPosition.dy - topPadding + scrollController.offset,
    );
    if (dragIndex == newIndex) return;
    // if (dragIndex == newIndex || dragIndex == newIndex - 1) return;

    if (newIndex == nodeIndex + 1 || newIndex == nodeIndex - 1) {
      dragIndex = null;
      dragNodeID = null;
    } else {
      dragIndex = newIndex;
      dragNodeID = doc.getNodeAt(newIndex)?.id;
    }
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
      targetIndex: dragIndex!,
    );
    doc.moveNode(
      nodeId: dragNode.id,
      targetIndex: dragIndex!,
    );
    dragIndex = null;
    dragNodeID = null;
    dragPositionDeltaY = null;
    dragAutoscrollTimer?.cancel();
    dragAutoscrollTimer = null;
    screenHeight = null;
    notifyListeners();
  }

  void onDragCompleted() {
    dragIndex = null;
    dragNodeID = null;
    dragPositionDeltaY = null;
    dragAutoscrollTimer?.cancel();
    dragAutoscrollTimer = null;
    screenHeight = null;
    notifyListeners();
  }

  void onDraggableCanceled(Velocity velocity, Offset offset) {
    dragIndex = null;
    dragNodeID = null;
    dragPositionDeltaY = null;
    dragAutoscrollTimer?.cancel();
    dragAutoscrollTimer = null;
    screenHeight = null;
    notifyListeners();
  }

  void _setAutoscrollTimer() {
    if (dragAutoscrollTimer != null) return;
    dragAutoscrollTimer = Timer.periodic(
      const Duration(milliseconds: 10),
      (_) => _autoScroll(),
    );
  }

  void _autoScroll() {
    if (dragPositionDeltaY == null || screenHeight == null) return;

    if (dragPositionDeltaY! < 100 && scrollController.position.pixels > 0) {
      scrollController.jumpTo(
        scrollController.position.pixels -
            autoscrollCoefficient * (1 - dragPositionDeltaY! / 100),
      );
    } else if (dragPositionDeltaY! > screenHeight! - 100 &&
        scrollController.position.pixels <
            scrollController.position.maxScrollExtent) {
      scrollController.jumpTo(
        // x je dragPositionDeltaY
        // y = ax + b
        // 0 = a*(screenHeight! - 100) + b
        // 1 = a*(screenHeight!) + b
        // 1 = a*(screenHeight!) - a*(screenHeight! - 100)
        // 1 = 100*a
        // a = 1/100
        // y = 1/100 * x + b
        // 1 = 1/100 * screenHeight! + b
        // b = 1 - 1/100 * screenHeight!
        // y = 1/100 * x + 1 - 1/100 * screenHeight!

        // 0 ako je dragPositionDeltaY == screenHeight! - 100
        // 1 ako je dragPositionDeltaY == screenHeight!
        scrollController.position.pixels +
            autoscrollCoefficient *
                (1 - (screenHeight! - dragPositionDeltaY!) / 100),
      );
    }
  }
}
