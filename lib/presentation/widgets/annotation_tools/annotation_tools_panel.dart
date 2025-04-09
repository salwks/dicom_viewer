import 'package:flutter/material.dart';

enum AnnotationTool { text, arrow, freehand, marker, rectangle, highlighter }

extension AnnotationToolExtension on AnnotationTool {
  String get name {
    switch (this) {
      case AnnotationTool.text:
        return '텍스트';
      case AnnotationTool.arrow:
        return '화살표';
      case AnnotationTool.freehand:
        return '자유 곡선';
      case AnnotationTool.marker:
        return '마커';
      case AnnotationTool.rectangle:
        return '사각형';
      case AnnotationTool.highlighter:
        return '하이라이터';
    }
  }

  IconData get icon {
    switch (this) {
      case AnnotationTool.text:
        return Icons.text_fields;
      case AnnotationTool.arrow:
        return Icons.arrow_forward;
      case AnnotationTool.freehand:
        return Icons.draw;
      case AnnotationTool.marker:
        return Icons.place;
      case AnnotationTool.rectangle:
        return Icons.crop_square;
      case AnnotationTool.highlighter:
        return Icons.format_color_fill;
    }
  }

  String get description {
    switch (this) {
      case AnnotationTool.text:
        return '텍스트 주석을 추가합니다.';
      case AnnotationTool.arrow:
        return '화살표로 특정 위치를 가리킵니다.';
      case AnnotationTool.freehand:
        return '자유롭게 그려서 원하는 부분을 표시합니다.';
      case AnnotationTool.marker:
        return '특정 위치에 마커를 추가합니다.';
      case AnnotationTool.rectangle:
        return '사각형으로 영역을 표시합니다.';
      case AnnotationTool.highlighter:
        return '영역을 강조 표시합니다.';
    }
  }
}

class AnnotationToolsPanel extends StatefulWidget {
  final Function(AnnotationTool) onToolSelected;
  final AnnotationTool? selectedTool;
  final VoidCallback? onClearAnnotations;
  final Function(Color)? onColorChanged;

  const AnnotationToolsPanel({
    super.key,
    required this.onToolSelected,
    this.selectedTool,
    this.onClearAnnotations,
    this.onColorChanged,
  });

  @override
  State<AnnotationToolsPanel> createState() => _AnnotationToolsPanelState();
}

class _AnnotationToolsPanelState extends State<AnnotationToolsPanel> {
  Color _selectedColor = Colors.green;

  final List<Color> _availableColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.cyan,
    Colors.white,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('주석 도구', style: Theme.of(context).textTheme.titleSmall),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.color_lens,
                        color: _selectedColor,
                        size: 20,
                      ),
                      onPressed: _showColorPicker,
                      tooltip: '색상 선택',
                    ),
                    if (widget.onClearAnnotations != null)
                      IconButton(
                        icon: const Icon(Icons.delete_sweep, size: 20),
                        onPressed: widget.onClearAnnotations,
                        tooltip: '주석 지우기',
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              children: [
                _buildToolButton(context, AnnotationTool.text),
                _buildToolButton(context, AnnotationTool.arrow),
                _buildToolButton(context, AnnotationTool.freehand),
                _buildToolButton(context, AnnotationTool.marker),
                _buildToolButton(context, AnnotationTool.rectangle),
                _buildToolButton(context, AnnotationTool.highlighter),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(BuildContext context, AnnotationTool tool) {
    final isSelected = widget.selectedTool == tool;

    return Tooltip(
      message: '${tool.name}\n${tool.description}',
      preferBelow: false,
      child: InkWell(
        onTap: () => widget.onToolSelected(tool),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 74,
          margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration:
              isSelected
                  ? BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  )
                  : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tool.icon,
                color: isSelected ? Theme.of(context).primaryColor : null,
              ),
              const SizedBox(height: 4),
              Text(
                tool.name,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('주석 색상 선택'),
            content: Container(
              width: 300,
              height: 100,
              alignment: Alignment.center,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children:
                    _availableColors.map((color) {
                      return InkWell(
                        onTap: () {
                          setState(() => _selectedColor = color);
                          if (widget.onColorChanged != null) {
                            widget.onColorChanged!(color);
                          }
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            border: Border.all(
                              color:
                                  color == Colors.white ? Colors.black : color,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child:
                              color == _selectedColor
                                  ? const Icon(Icons.check, color: Colors.black)
                                  : null,
                        ),
                      );
                    }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
            ],
          ),
    );
  }
}

/// 텍스트 주석 입력을 위한 다이얼로그
class AnnotationTextDialog extends StatelessWidget {
  final TextEditingController textController;
  final Function(String) onTextSubmitted;

  const AnnotationTextDialog({
    super.key,
    required this.textController,
    required this.onTextSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('텍스트 주석 추가'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: textController,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '주석 내용을 입력하세요',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            if (textController.text.isNotEmpty) {
              onTextSubmitted(textController.text);
            }
            Navigator.pop(context);
          },
          child: const Text('추가'),
        ),
      ],
    );
  }
}
