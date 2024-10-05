import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

/// [DocumentNode] for a horizontal rule, which represents a full-width
/// horizontal separation in a document.
class DragIndicatorNode extends BlockNode with ChangeNotifier {
  DragIndicatorNode({String? id}) : id = id ?? Editor.createNodeId() {
    putMetadataValue("blockType", const NamedAttribution('dragIndicator'));
  }

  @override
  final String id;

  @override
  String? copyContent(dynamic selection) {
    if (selection is! UpstreamDownstreamNodeSelection) {
      throw Exception(
        'HorizontalRuleNode can only copy content from '
        'a UpstreamDownstreamNodeSelection.',
      );
    }

    return !selection.isCollapsed ? '---' : null;
  }

  @override
  bool hasEquivalentContent(DocumentNode other) {
    return other is DragIndicatorNode;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DragIndicatorNode &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  DragIndicatorNode copy() => DragIndicatorNode(id: id);
}

class DragIndicatorComponentBuilder implements ComponentBuilder {
  DragIndicatorComponentBuilder({
    required this.dragIndicatorColor,
    required this.reorderNodesNotifier,
  });

  final Color dragIndicatorColor;
  final ReorderNodesNotifier? reorderNodesNotifier;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) {
    if (node is! DragIndicatorNode) {
      return null;
    }

    return DragIndicatorComponentViewModel(
      nodeId: node.id,
      selectionColor: const Color(0x00000000),
      caretColor: const Color(0x00000000),
    );
  }

  @override
  Widget? createComponent(SingleColumnDocumentComponentContext componentContext,
      SingleColumnLayoutComponentViewModel componentViewModel) {
    if (componentViewModel is! DragIndicatorComponentViewModel) {
      return null;
    }

    return DragIndicatorComponent(
      nodeId: componentViewModel.nodeId,
      componentKey: componentContext.componentKey,
      selection: componentViewModel.selection?.nodeSelection
          as UpstreamDownstreamNodeSelection?,
      selectionColor: componentViewModel.selectionColor,
      showCaret: componentViewModel.caret != null,
      caretColor: componentViewModel.caretColor,
      dragIndicatorColor: dragIndicatorColor,
      reorderNodesNotifier: reorderNodesNotifier,
    );
  }
}

class DragIndicatorComponentViewModel
    extends SingleColumnLayoutComponentViewModel
    with SelectionAwareViewModelMixin {
  DragIndicatorComponentViewModel({
    required super.nodeId,
    super.maxWidth,
    super.padding = EdgeInsets.zero,
    DocumentNodeSelection? selection,
    Color selectionColor = Colors.transparent,
    this.caret,
    required this.caretColor,
  }) {
    super.selection = selection;
    super.selectionColor = selectionColor;
  }

  UpstreamDownstreamNodePosition? caret;
  Color caretColor;

  @override
  DragIndicatorComponentViewModel copy() {
    return DragIndicatorComponentViewModel(
      nodeId: nodeId,
      maxWidth: maxWidth,
      padding: padding,
      selection: selection,
      selectionColor: selectionColor,
      caret: caret,
      caretColor: caretColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is DragIndicatorComponentViewModel &&
          runtimeType == other.runtimeType &&
          nodeId == other.nodeId &&
          selection == other.selection &&
          selectionColor == other.selectionColor &&
          caret == other.caret &&
          caretColor == other.caretColor;

  @override
  int get hashCode =>
      super.hashCode ^
      nodeId.hashCode ^
      selection.hashCode ^
      selectionColor.hashCode ^
      caret.hashCode ^
      caretColor.hashCode;
}

/// Displays a horizontal rule in a document.
class DragIndicatorComponent extends StatelessWidget {
  const DragIndicatorComponent({
    Key? key,
    required this.componentKey,
    required this.nodeId,
    required this.dragIndicatorColor,
    required this.reorderNodesNotifier,
    this.selectionColor = Colors.blue,
    this.selection,
    required this.caretColor,
    this.showCaret = false,
  }) : super(key: key);

  final String nodeId;
  final GlobalKey componentKey;
  final Color dragIndicatorColor;
  final Color selectionColor;
  final UpstreamDownstreamNodeSelection? selection;
  final Color caretColor;
  final bool showCaret;
  final ReorderNodesNotifier? reorderNodesNotifier;

  Widget _buildDragIndicator(Color color) {
    return IgnorePointer(
      child: SelectableBox(
        selection: selection,
        selectionColor: selectionColor,
        child: BoxComponent(
          key: componentKey,
          child: Divider(
            height: 0,
            color: color,
            thickness: 2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return reorderNodesNotifier == null
        ? _buildDragIndicator(Colors.transparent)
        : ListenableBuilder(
            listenable: reorderNodesNotifier!,
            builder: (_, __) {
              return _buildDragIndicator(
                reorderNodesNotifier!.isDragNodeVisible(nodeId)
                    ? dragIndicatorColor
                    : Colors.transparent,
              );
            },
          );
  }
}
