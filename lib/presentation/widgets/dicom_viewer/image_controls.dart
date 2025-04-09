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
                width: 48,
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
                width: 48,
                child: Text(
                  '${(contrast * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          // 이미지 스크롤 컨트롤 (시리즈 내에서 슬라이스 이동)
          if (totalImages > 1) _buildImageNavigationControls(),
        ],
      ),
    );
  }

  Widget _buildImageNavigationControls() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous),
              onPressed: currentIndex > 0 ? () => onIndexChanged(0) : null,
              tooltip: '첫 이미지',
              iconSize: 20,
            ),
            IconButton(
              icon: const Icon(Icons.navigate_before),
              onPressed:
                  currentIndex > 0
                      ? () => onIndexChanged(currentIndex - 1)
                      : null,
              tooltip: '이전 이미지',
              iconSize: 20,
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${currentIndex + 1} / $totalImages',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.navigate_next),
              onPressed:
                  currentIndex < totalImages - 1
                      ? () => onIndexChanged(currentIndex + 1)
                      : null,
              tooltip: '다음 이미지',
              iconSize: 20,
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed:
                  currentIndex < totalImages - 1
                      ? () => onIndexChanged(totalImages - 1)
                      : null,
              tooltip: '마지막 이미지',
              iconSize: 20,
            ),
          ],
        ),

        // 슬라이더
        SliderTheme(
          data: const SliderThemeData(
            trackHeight: 4.0,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
          ),
          child: Slider(
            value: currentIndex.toDouble(),
            min: 0,
            max: (totalImages - 1).toDouble(),
            divisions: totalImages > 1 ? totalImages - 1 : 1,
            label: '${currentIndex + 1} / $totalImages',
            onChanged: (value) => onIndexChanged(value.toInt()),
          ),
        ),
      ],
    );
  }
}

/// 향상된 이미지 조작 패널 (팝업 형태)
class ImageProcessingPanel extends StatelessWidget {
  final double brightness;
  final double contrast;
  final bool invertColors;
  final int rotationAngle;
  final bool flipHorizontal;
  final bool flipVertical;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onContrastChanged;
  final ValueChanged<bool> onInvertColorsChanged;
  final ValueChanged<int> onRotationAngleChanged;
  final ValueChanged<bool> onFlipHorizontalChanged;
  final ValueChanged<bool> onFlipVerticalChanged;
  final VoidCallback onResetSettings;

  const ImageProcessingPanel({
    super.key,
    required this.brightness,
    required this.contrast,
    required this.invertColors,
    required this.rotationAngle,
    required this.flipHorizontal,
    required this.flipVertical,
    required this.onBrightnessChanged,
    required this.onContrastChanged,
    required this.onInvertColorsChanged,
    required this.onRotationAngleChanged,
    required this.onFlipHorizontalChanged,
    required this.onFlipVerticalChanged,
    required this.onResetSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('이미지 설정', style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          _buildBrightnessControl(),
          _buildContrastControl(),
          _buildInvertColorsControl(),
          _buildRotationControl(),
          _buildFlipControls(),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              onResetSettings();
              Navigator.pop(context);
            },
            child: const Text('설정 초기화'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBrightnessControl() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('밝기'),
          Row(
            children: [
              const Icon(Icons.brightness_low, size: 20),
              Expanded(
                child: Slider(
                  value: brightness,
                  min: -0.5,
                  max: 0.5,
                  onChanged: onBrightnessChanged,
                ),
              ),
              const Icon(Icons.brightness_high, size: 20),
              SizedBox(
                width: 50,
                child: Text(
                  '${(brightness * 100).toStringAsFixed(0)}%',
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContrastControl() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('대비'),
          Row(
            children: [
              const Icon(Icons.contrast, size: 20),
              Expanded(
                child: Slider(
                  value: contrast,
                  min: 0.5,
                  max: 2.0,
                  onChanged: onContrastChanged,
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  '${(contrast * 100).toStringAsFixed(0)}%',
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvertColorsControl() {
    return SwitchListTile(
      title: const Text('색상 반전'),
      value: invertColors,
      onChanged: onInvertColorsChanged,
      secondary: const Icon(Icons.invert_colors),
    );
  }

  Widget _buildRotationControl() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.rotate_90_degrees_cw, size: 24),
          const SizedBox(width: 16),
          const Text('회전'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.rotate_left),
            onPressed: () => onRotationAngleChanged((rotationAngle - 90) % 360),
          ),
          Text('$rotationAngle°'),
          IconButton(
            icon: const Icon(Icons.rotate_right),
            onPressed: () => onRotationAngleChanged((rotationAngle + 90) % 360),
          ),
        ],
      ),
    );
  }

  Widget _buildFlipControls() {
    return Row(
      children: [
        Expanded(
          child: SwitchListTile(
            title: const Text('수평 반전'),
            value: flipHorizontal,
            onChanged: onFlipHorizontalChanged,
            secondary: const Icon(Icons.flip),
          ),
        ),
        Expanded(
          child: SwitchListTile(
            title: const Text('수직 반전'),
            value: flipVertical,
            onChanged: onFlipVerticalChanged,
            secondary: Transform.rotate(
              angle: 1.5708, // 90도 (파이/2 라디안)
              child: const Icon(Icons.flip),
            ),
          ),
        ),
      ],
    );
  }
}
