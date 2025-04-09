import 'package:flutter/material.dart';

enum MeasurementTool { line, angle, rectangle, ellipse, freehand, hounsfield }

extension MeasurementToolExtension on MeasurementTool {
  String get name {
    switch (this) {
      case MeasurementTool.line:
        return '길이 측정';
      case MeasurementTool.angle:
        return '각도 측정';
      case MeasurementTool.rectangle:
        return '사각형 영역';
      case MeasurementTool.ellipse:
        return '원형 영역';
      case MeasurementTool.freehand:
        return '자유 곡선';
      case MeasurementTool.hounsfield:
        return 'HU 값';
    }
  }

  IconData get icon {
    switch (this) {
      case MeasurementTool.line:
        return Icons.straighten;
      case MeasurementTool.angle:
        return Icons.architecture;
      case MeasurementTool.rectangle:
        return Icons.crop_square;
      case MeasurementTool.ellipse:
        return Icons.circle_outlined;
      case MeasurementTool.freehand:
        return Icons.gesture;
      case MeasurementTool.hounsfield:
        return Icons.colorize;
    }
  }

  String get description {
    switch (this) {
      case MeasurementTool.line:
        return '두 점 사이의 거리를 측정합니다.';
      case MeasurementTool.angle:
        return '세 점으로 각도를 측정합니다.';
      case MeasurementTool.rectangle:
        return '직사각형 영역의 면적을 측정합니다.';
      case MeasurementTool.ellipse:
        return '타원형 영역의 면적을 측정합니다.';
      case MeasurementTool.freehand:
        return '자유롭게 그려서 곡선을 측정합니다.';
      case MeasurementTool.hounsfield:
        return '특정 지점의 하운스필드 단위(HU) 값을 측정합니다.';
    }
  }
}

class MeasurementToolsPanel extends StatelessWidget {
  final Function(MeasurementTool) onToolSelected;
  final MeasurementTool? selectedTool;
  final VoidCallback? onClearMeasurements;
  final VoidCallback? onSaveMeasurements;

  const MeasurementToolsPanel({
    super.key,
    required this.onToolSelected,
    this.selectedTool,
    this.onClearMeasurements,
    this.onSaveMeasurements,
  });

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
                Text('측정 도구', style: Theme.of(context).textTheme.titleSmall),
                Row(
                  children: [
                    if (onSaveMeasurements != null)
                      IconButton(
                        icon: const Icon(Icons.save_alt, size: 20),
                        onPressed: onSaveMeasurements,
                        tooltip: '측정값 저장',
                      ),
                    if (onClearMeasurements != null)
                      IconButton(
                        icon: const Icon(Icons.delete_sweep, size: 20),
                        onPressed: onClearMeasurements,
                        tooltip: '측정값 지우기',
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
                _buildToolButton(context, MeasurementTool.line),
                _buildToolButton(context, MeasurementTool.angle),
                _buildToolButton(context, MeasurementTool.rectangle),
                _buildToolButton(context, MeasurementTool.ellipse),
                _buildToolButton(context, MeasurementTool.freehand),
                _buildToolButton(context, MeasurementTool.hounsfield),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(BuildContext context, MeasurementTool tool) {
    final isSelected = selectedTool == tool;

    return Tooltip(
      message: '${tool.name}\n${tool.description}',
      preferBelow: false,
      child: InkWell(
        onTap: () => onToolSelected(tool),
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
}

/// 측정 결과 표시를 위한 위젯
class MeasurementResultsPanel extends StatelessWidget {
  final List<Map<String, dynamic>> measurements;
  final Function(int) onDeleteMeasurement;
  final VoidCallback onClearAllMeasurements;

  const MeasurementResultsPanel({
    super.key,
    required this.measurements,
    required this.onDeleteMeasurement,
    required this.onClearAllMeasurements,
  });

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty) {
      return const Center(child: Text('측정 결과가 없습니다.'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('측정 결과', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                icon: const Icon(Icons.delete_sweep),
                onPressed: onClearAllMeasurements,
                label: const Text('모두 지우기'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: measurements.length,
            itemBuilder: (context, index) {
              final measurement = measurements[index];
              return _buildMeasurementItem(context, index, measurement);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementItem(
    BuildContext context,
    int index,
    Map<String, dynamic> measurement,
  ) {
    final type = measurement['type'] as String;
    final value = measurement['value'];
    final unit = measurement['unit'] as String;

    IconData iconData;
    Color color;

    switch (type) {
      case 'distance':
        iconData = Icons.straighten;
        color = Colors.blue;
        break;
      case 'angle':
        iconData = Icons.architecture;
        color = Colors.orange;
        break;
      case 'area':
        iconData =
            measurement['shape'] == 'rectangle'
                ? Icons.crop_square
                : Icons.circle_outlined;
        color = Colors.green;
        break;
      case 'hounsfield':
        iconData = Icons.colorize;
        color = Colors.purple;
        break;
      default:
        iconData = Icons.gesture;
        color = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(iconData, color: color),
        ),
        title: Text('$type 측정'),
        subtitle: Text('$value $unit'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => onDeleteMeasurement(index),
          tooltip: '측정 삭제',
        ),
      ),
    );
  }
}
