import 'package:flutter/material.dart';

class ImageControls extends StatelessWidget {
  final double brightness;
  final double contrast;
  final int currentIndex;
  final int totalImages;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onContrastChanged;
  final ValueChanged<int> onIndexChanged;

  const ImageControls({
    super.key,
    required this.brightness,
    required this.contrast,
    required this.currentIndex,
    required this.totalImages,
    required this.onBrightnessChanged,
    required this.onContrastChanged,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 밝기 조절 슬라이더
          Row(
            children: [
              const Icon(Icons.brightness_6, size: 20),
              const SizedBox(width: 8),
              const Text('밝기:'),
              Expanded(
                child: Slider(
                  value: brightness,
                  min: -0.5,
                  max: 0.5,
                  divisions: 100,
                  label: '${(brightness * 100).toStringAsFixed(0)}%',
                  onChanged: onBrightnessChanged,
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '${(brightness * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          // 대비 조절 슬라이더
          Row(
            children: [
              const Icon(Icons.contrast, size: 20),
              const SizedBox(width: 8),
              const Text('대비:'),
              Expanded(
                child: Slider(
                  value: contrast,
                  min: 0.5,
                  max: 2.0,
                  divisions: 100,
                  label: '${(contrast * 100).toStringAsFixed(0)}%',
                  onChanged: onContrastChanged,
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '${(contrast * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          // 이미지 스크롤 컨트롤 (시리즈 내에서 슬라이스 이동)
          if (totalImages > 1)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: currentIndex > 0 ? () => onIndexChanged(0) : null,
                  tooltip: '첫 이미지',
                ),
                IconButton(
                  icon: const Icon(Icons.navigate_before),
                  onPressed:
                      currentIndex > 0
                          ? () => onIndexChanged(currentIndex - 1)
                          : null,
                  tooltip: '이전 이미지',
                ),
                Expanded(
                  child: Slider(
                    value: currentIndex.toDouble(),
                    min: 0,
                    max: (totalImages - 1).toDouble(),
                    divisions: totalImages - 1,
                    label: '${currentIndex + 1} / $totalImages',
                    onChanged: (value) => onIndexChanged(value.toInt()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.navigate_next),
                  onPressed:
                      currentIndex < totalImages - 1
                          ? () => onIndexChanged(currentIndex + 1)
                          : null,
                  tooltip: '다음 이미지',
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed:
                      currentIndex < totalImages - 1
                          ? () => onIndexChanged(totalImages - 1)
                          : null,
                  tooltip: '마지막 이미지',
                ),
              ],
            ),
        ],
      ),
    );
  }
}
