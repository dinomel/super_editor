import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:super_editor/src/default_editor/drag_indicator.dart';
import 'package:super_editor/super_editor.dart';

class ReorderNodesNotifier extends ChangeNotifier {
  final MutableDocument doc;
  final ScrollController scrollController;
  final Editor docEditor;
  int? dragIndex;
  String? dragNodeID;
  String? nodeID;
  double? dragPositionDeltaY;
  Timer? dragAutoscrollTimer;
  double? screenHeight;
  final double topPadding;
  final autoscrollCoefficient = 8;

  bool isDragNodeVisible(String nodeId) => dragNodeID == nodeId;

  ReorderNodesNotifier({
    required this.docEditor,
    required this.scrollController,
    this.topPadding = 0,
  }) : doc = docEditor.document;

  @override
  void dispose() {
    dragAutoscrollTimer?.cancel();
    super.dispose();
  }

  void onDragStarted(String nodeID) {
    this.nodeID = nodeID;
    log('onDragStarted triggered');
    final requests = List<EditRequest>.generate(doc.nodeCount + 1, (index) {
      return InsertNodeAtIndexRequest(
        nodeIndex: index,
        newNode: DragIndicatorNode(),
      );
    }).reversed.toList();
    docEditor.execute(requests);
  }

  void onDragUpdate({
    required BuildContext context,
    required DragUpdateDetails details,
    required int Function(double) findComponentIndexAtOffset,
  }) {
    final mediaQuery = MediaQuery.of(Scaffold.of(context).context);
    screenHeight = MediaQuery.of(context).size.height -
        mediaQuery.viewInsets.bottom -
        topPadding;
    _setAutoscrollTimer();
    dragPositionDeltaY = details.globalPosition.dy - topPadding;
    final newIndex = findComponentIndexAtOffset(
      details.globalPosition.dy - topPadding + scrollController.offset,
    );
    if (dragIndex == newIndex) return;
    dragIndex = newIndex;
    dragNodeID = doc.getNodeAt(newIndex)?.id;
    log('dragIndex: $dragIndex');
    notifyListeners();
  }

  void onDragEnd() {
    log('onDragEnd triggered');
    final requests = doc
        .whereType<DragIndicatorNode>()
        .map((e) => DeleteNodeRequest(nodeId: e.id))
        .toList();
    if (nodeID == null ||
        dragIndex == null ||
        dragIndex! < 0 ||
        dragIndex! >= doc.nodeCount) {
      docEditor.execute(requests);
      return;
    }
    docEditor.execute([
      MoveNodeRequest(nodeId: nodeID!, newIndex: dragIndex!),
    ]);
    docEditor.execute(requests);
    dragIndex = null;
    dragNodeID = null;
    nodeID = null;
    dragPositionDeltaY = null;
    dragAutoscrollTimer?.cancel();
    dragAutoscrollTimer = null;
    screenHeight = null;
    notifyListeners();
  }

  void onDraggableCanceled(Velocity velocity, Offset offset) {
    if (nodeID == null) return;
    log('onDraggableCanceled triggered');
    final requests = doc
        .whereType<DragIndicatorNode>()
        .map((e) => DeleteNodeRequest(nodeId: e.id))
        .toList();
    docEditor.execute(requests);
    dragIndex = null;
    dragNodeID = null;
    nodeID = null;
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
