import 'package:flutter/material.dart';

enum AnnotationTool { text, arrow, freehand, marker, rectangle }

class AnnotationToolsPanel extends StatelessWidget {
  final Function(AnnotationTool) onToolSelected;
  final AnnotationTool? selectedTool;

  const AnnotationToolsPanel({
    super.key,
    required this.onToolSelected,
    this.selectedTool,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Theme.of(context).cardColor,
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
          _buildToolButton(context, AnnotationTool.marker, Icons.place, '마커'),
          _buildToolButton(
            context,
            AnnotationTool.rectangle,
            Icons.crop_square,
            '사각형',
          ),
          // 구분선
          const VerticalDivider(
            width: 32,
            thickness: 1,
            indent: 8,
            endIndent: 8,
          ),
          // 주석 색상 선택 버튼
          InkWell(
            onTap: () {
              // TODO: 색상 선택 대화상자 표시
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.color_lens),
                  SizedBox(height: 4),
                  Text('색상', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
          // 주석 초기화 버튼
          InkWell(
            onTap: () {
              // TODO: 주석 초기화 작업
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('주석이 초기화되었습니다'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.delete_sweep),
                  SizedBox(height: 4),
                  Text('초기화', style: TextStyle(fontSize: 12)),
                ],
              ),
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

    return InkWell(
      onTap: () => onToolSelected(tool),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
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
            ),
          ],
        ),
      ),
    );
  }
}
