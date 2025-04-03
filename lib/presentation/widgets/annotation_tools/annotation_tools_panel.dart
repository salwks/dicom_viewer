import 'package:flutter/material.dart';

enum AnnotationTool { text, arrow, freehand, marker, rectangle }

class AnnotationToolsPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Row(
              children: [
                const Text(
                  '주석 도구',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                _buildColorPicker(context),
                const SizedBox(width: 16),
                _buildClearButton(context),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              children: [
                _buildToolButton(
                  context,
                  AnnotationTool.text,
                  Icons.text_fields,
                  '텍스트',
                ),
                _buildToolButton(
                  context,
                  AnnotationTool.arrow,
                  Icons.arrow_forward,
                  '화살표',
                ),
                _buildToolButton(
                  context,
                  AnnotationTool.freehand,
                  Icons.draw,
                  '자유 곡선',
                ),
                _buildToolButton(
                  context,
                  AnnotationTool.marker,
                  Icons.place,
                  '마커',
                ),
                _buildToolButton(
                  context,
                  AnnotationTool.rectangle,
                  Icons.crop_square,
                  '사각형',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(
    BuildContext context,
    AnnotationTool tool,
    IconData icon,
    String label,
  ) {
    final isSelected = selectedTool == tool;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: InkWell(
        onTap: () => onToolSelected(tool),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 80,
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
                icon,
                color: isSelected ? Theme.of(context).primaryColor : null,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.delete_sweep),
      tooltip: '주석 초기화',
      onPressed: onClearAnnotations,
    );
  }

  Widget _buildColorPicker(BuildContext context) {
    final colors = [
      Colors.green,
      Colors.yellow,
      Colors.red,
      Colors.blue,
      Colors.purple,
      Colors.orange,
    ];

    return PopupMenuButton<Color>(
      tooltip: '색상 선택',
      icon: const Icon(Icons.color_lens),
      itemBuilder: (context) {
        return colors.map((color) {
          return PopupMenuItem<Color>(
            value: color,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(_colorToName(color)),
              ],
            ),
          );
        }).toList();
      },
      onSelected: onColorChanged,
    );
  }

  String _colorToName(Color color) {
    if (color == Colors.green) return '초록';
    if (color == Colors.yellow) return '노랑';
    if (color == Colors.red) return '빨강';
    if (color == Colors.blue) return '파랑';
    if (color == Colors.purple) return '보라';
    if (color == Colors.orange) return '주황';
    return '기타';
  }
}
