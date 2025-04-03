import 'package:flutter/material.dart';

enum MeasurementTool { line, angle, rectangle, ellipse, freehand }

class MeasurementToolsPanel extends StatelessWidget {
  final Function(MeasurementTool) onToolSelected;
  final MeasurementTool? selectedTool;

  const MeasurementToolsPanel({
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
            MeasurementTool.line,
            Icons.straighten,
            '길이 측정',
          ),
          _buildToolButton(
            context,
            MeasurementTool.angle,
            Icons.architecture,
            '각도 측정',
          ),
          _buildToolButton(
            context,
            MeasurementTool.rectangle,
            Icons.crop_square,
            '사각형 영역',
          ),
          _buildToolButton(
            context,
            MeasurementTool.ellipse,
            Icons.circle_outlined,
            '원형 영역',
          ),
          _buildToolButton(
            context,
            MeasurementTool.freehand,
            Icons.gesture,
            '자유 곡선',
          ),
          // 구분선
          const VerticalDivider(
            width: 32,
            thickness: 1,
            indent: 8,
            endIndent: 8,
          ),
          // 측정 초기화 버튼
          InkWell(
            onTap: () {
              // TODO: 측정 초기화 작업
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('측정이 초기화되었습니다'),
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
    MeasurementTool tool,
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
