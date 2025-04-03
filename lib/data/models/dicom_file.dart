import 'dart:typed_data';

class DicomTag {
  final String name;
  final String group;
  final String element;
  final String vr; // Value Representation
  final String value;

  DicomTag({
    required this.name,
    required this.group,
    required this.element,
    required this.vr,
    required this.value,
  });

  @override
  String toString() {
    return '($group,$element) $name [$vr]: $value';
  }
}

class DicomImage {
  final int index;
  final Uint8List? pixelData;
  final int width;
  final int height;
  final int bitsAllocated;
  final int bitsStored;
  final int highBit;
  final int samplesPerPixel;
  final bool isColor;
  final String photometricInterpretation;

  // 이미지 윈도우 레벨 속성
  final double windowCenter;
  final double windowWidth;

  DicomImage({
    required this.index,
    required this.pixelData,
    required this.width,
    required this.height,
    required this.bitsAllocated,
    required this.bitsStored,
    required this.highBit,
    required this.samplesPerPixel,
    required this.isColor,
    required this.photometricInterpretation,
    this.windowCenter = 0,
    this.windowWidth = 0,
  });
}

class DicomFile {
  final String filePath;
  final String patientName;
  final String patientId;
  final String studyDate;
  final String studyDescription;
  final String seriesDescription;
  final String modality;
  final List<DicomImage> images;
  final Map<String, DicomTag> tags;
  final DateTime dateAdded;

  DicomFile({
    required this.filePath,
    required this.patientName,
    required this.patientId,
    required this.studyDate,
    required this.studyDescription,
    required this.seriesDescription,
    required this.modality,
    required this.images,
    required this.tags,
    required this.dateAdded,
  });

  // 메타데이터 정보 요약
  String get summary {
    return '$patientName ($patientId) - $modality - $studyDate';
  }

  // 이미지 개수
  int get imageCount => images.length;

  // 첫번째 이미지
  DicomImage? get firstImage => images.isNotEmpty ? images.first : null;
}
