import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../models/dicom_file.dart';

class DicomService {
  // DICOM 파일 헤더 바이트 식별자 (DICM)
  static const List<int> dicomMagicBytes = [68, 73, 67, 77];

  /// DICOM 파일을 로드하고 파싱합니다.
  Future<DicomFile> loadDicomFile(String filePath) async {
    try {
      // 파일 존재 여부 확인
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('파일이 존재하지 않습니다: $filePath');
      }

      // 파일 바이트 읽기
      final bytes = await file.readAsBytes();

      // DICOM 파일 유효성 검사
      if (!_isValidDicomFile(bytes)) {
        // 현재는 더미 데이터로 대체하고, 유효하지 않은 경우에도 진행
        // 실제 구현에서는 예외를 발생시키는 것이 좋음
        print('경고: 유효한 DICOM 파일이 아닐 수 있습니다. 더미 데이터로 진행합니다.');
      }

      // 실제 DICOM 파일 파싱 로직은 별도 라이브러리나 네이티브 코드와의 연동이 필요함
      // 현재는 더미 데이터 사용

      // 태그 파싱 (더미 데이터)
      final dummyTags = _parseDicomTags(bytes);

      // 픽셀 데이터 추출 (더미 데이터)
      final List<DicomImage> images = await _extractPixelData(bytes, filePath);

      // DicomFile 객체 생성
      return DicomFile(
        filePath: filePath,
        patientName: dummyTags['00100010']?.value ?? '알 수 없음',
        patientId: dummyTags['00100020']?.value ?? '알 수 없음',
        studyDate: _formatDate(dummyTags['00080020']?.value ?? ''),
        studyDescription: dummyTags['00081030']?.value ?? '',
        seriesDescription: dummyTags['0008103E']?.value ?? '',
        modality: dummyTags['00080060']?.value ?? 'XX',
        images: images,
        tags: dummyTags,
        dateAdded: DateTime.now(),
      );
    } catch (e) {
      print('DICOM 파일 로드 오류: $e');
      throw Exception('DICOM 파일을 로드할 수 없습니다: $e');
    }
  }

  /// DICOM 파일 유효성 검사
  bool _isValidDicomFile(Uint8List bytes) {
    // 실제 DICOM 검증 방법:
    // 1. 파일 크기 체크 (최소 132 바이트 이상이어야 함)
    if (bytes.length < 132) return false;

    // 2. DICM 시그니처 확인 (128 바이트 이후에 'DICM' 문자열이 있어야 함)
    for (int i = 0; i < 4; i++) {
      if (bytes[128 + i] != dicomMagicBytes[i]) {
        return false;
      }
    }

    return true;
  }

  /// DICOM 태그 파싱 (더미 구현)
  Map<String, DicomTag> _parseDicomTags(Uint8List bytes) {
    // 실제 구현에서는 바이트에서 DICOM 태그를 파싱
    // 지금은 더미 데이터 제공

    return <String, DicomTag>{
      '00100010': DicomTag(
        name: 'PatientName',
        group: '0010',
        element: '0010',
        vr: 'PN',
        value: '홍길동',
      ),
      '00100020': DicomTag(
        name: 'PatientID',
        group: '0010',
        element: '0020',
        vr: 'LO',
        value: '12345678',
      ),
      '00080020': DicomTag(
        name: 'StudyDate',
        group: '0008',
        element: '0020',
        vr: 'DA',
        value: '20230101',
      ),
      '00080060': DicomTag(
        name: 'Modality',
        group: '0008',
        element: '0060',
        vr: 'CS',
        value: 'CT',
      ),
      '00081030': DicomTag(
        name: 'StudyDescription',
        group: '0008',
        element: '1030',
        vr: 'LO',
        value: 'CT BRAIN',
      ),
      '0008103E': DicomTag(
        name: 'SeriesDescription',
        group: '0008',
        element: '103E',
        vr: 'LO',
        value: 'AXIAL',
      ),
      '00280010': DicomTag(
        name: 'Rows',
        group: '0028',
        element: '0010',
        vr: 'US',
        value: '512',
      ),
      '00280011': DicomTag(
        name: 'Columns',
        group: '0028',
        element: '0011',
        vr: 'US',
        value: '512',
      ),
      '00280100': DicomTag(
        name: 'BitsAllocated',
        group: '0028',
        element: '0100',
        vr: 'US',
        value: '16',
      ),
      '00280101': DicomTag(
        name: 'BitsStored',
        group: '0028',
        element: '0101',
        vr: 'US',
        value: '12',
      ),
      '00280102': DicomTag(
        name: 'HighBit',
        group: '0028',
        element: '0102',
        vr: 'US',
        value: '11',
      ),
      '00280103': DicomTag(
        name: 'PixelRepresentation',
        group: '0028',
        element: '0103',
        vr: 'US',
        value: '0',
      ),
      '00281050': DicomTag(
        name: 'WindowCenter',
        group: '0028',
        element: '1050',
        vr: 'DS',
        value: '40',
      ),
      '00281051': DicomTag(
        name: 'WindowWidth',
        group: '0028',
        element: '1051',
        vr: 'DS',
        value: '400',
      ),
      '00281052': DicomTag(
        name: 'RescaleIntercept',
        group: '0028',
        element: '1052',
        vr: 'DS',
        value: '-1024',
      ),
      '00281053': DicomTag(
        name: 'RescaleSlope',
        group: '0028',
        element: '1053',
        vr: 'DS',
        value: '1',
      ),
    };
  }

  /// 픽셀 데이터 추출 (더미 구현)
  Future<List<DicomImage>> _extractPixelData(
    Uint8List bytes,
    String filePath,
  ) async {
    // 실제 구현에서는 바이트에서 픽셀 데이터 추출
    // 지금은 더미 이미지 생성

    // 테스트용 이미지 크기
    final imageWidth = 512;
    final imageHeight = 512;

    // 더미 이미지 생성 (3개의 슬라이스 생성)
    final List<DicomImage> images = [];
    final sliceCount = 3;

    for (int i = 0; i < sliceCount; i++) {
      // 각 슬라이스마다 약간 다른 더미 이미지 생성
      final pixelData = await _createDummyImage(imageWidth, imageHeight, i);

      images.add(
        DicomImage(
          index: i,
          pixelData: pixelData,
          width: imageWidth,
          height: imageHeight,
          bitsAllocated: 16,
          bitsStored: 12,
          highBit: 11,
          samplesPerPixel: 1,
          isColor: false,
          photometricInterpretation: 'MONOCHROME2',
          windowCenter: 40,
          windowWidth: 400,
        ),
      );
    }

    return images;
  }

  /// 더미 테스트 이미지를 생성합니다.
  Future<Uint8List> _createDummyImage(
    int width,
    int height,
    int sliceIndex,
  ) async {
    try {
      // 이미지 생성
      final image = img.Image(width: width, height: height);

      // 배경색 채우기 (회색 - 슬라이스마다 약간 다름)
      int bgValue = 100 + (sliceIndex * 20);
      bgValue = bgValue.clamp(0, 255);
      img.fill(image, color: img.ColorRgb8(bgValue, bgValue, bgValue));

      // 중앙에 원 그리기
      int centerX = width ~/ 2;
      int centerY = height ~/ 2;
      int radius = math.min(width, height) ~/ (4 + sliceIndex); // 슬라이스마다 크기 다름

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          int distanceSquared =
              (x - centerX) * (x - centerX) + (y - centerY) * (y - centerY);
          if (distanceSquared <= radius * radius) {
            // 원 내부는 밝은 색 (슬라이스마다 약간 다름)
            int value = 200 + (sliceIndex * 15);
            value = value.clamp(0, 255);
            image.setPixel(x, y, img.ColorRgb8(value, value, value));
          }
        }
      }

      // 십자가 그리기
      for (int x = 0; x < width; x++) {
        image.setPixel(x, centerY, img.ColorRgb8(200, 200, 200));
      }
      for (int y = 0; y < height; y++) {
        image.setPixel(centerX, y, img.ColorRgb8(200, 200, 200));
      }

      // 슬라이스 번호 표시
      img.drawString(
        image,
        'Slice ${sliceIndex + 1}',
        font: img.arial24,
        x: 20,
        y: 20,
        color: img.ColorRgb8(255, 255, 255),
      );

      // PNG로 인코딩
      return Uint8List.fromList(img.encodePng(image));
    } catch (e) {
      print('더미 이미지 생성 오류: $e');
      // 오류 발생 시 빈 데이터 반환
      return Uint8List(0);
    }
  }

  /// 픽셀 데이터를 처리하여 이미지로 변환합니다.
  /// 밝기와 대비 조정 적용
  Future<Uint8List> convertPixelDataToImage(
    DicomImage dicomImage, {
    double brightness = 0.0,
    double contrast = 1.0,
    bool invertColors = false,
    int rotationAngle = 0, // 0, 90, 180, 270도
    bool flipHorizontal = false,
    bool flipVertical = false,
  }) async {
    try {
      if (dicomImage.pixelData == null || dicomImage.pixelData!.isEmpty) {
        throw Exception('픽셀 데이터가 없습니다');
      }

      // 이미지 디코딩
      final image = img.decodePng(dicomImage.pixelData!);
      if (image == null) {
        throw Exception('이미지를 디코딩할 수 없습니다');
      }

      // 변환된 이미지 생성
      img.Image processedImage = image;

      // 이미지 회전 적용
      if (rotationAngle != 0) {
        int rotations = (rotationAngle ~/ 90) % 4;
        for (int i = 0; i < rotations; i++) {
          processedImage = img.copyRotate(processedImage, angle: 90);
        }
      }

      // 좌우 반전 적용
      if (flipHorizontal) {
        processedImage = img.flipHorizontal(processedImage);
      }

      // 상하 반전 적용
      if (flipVertical) {
        processedImage = img.flipVertical(processedImage);
      }

      // 색상 반전 적용
      if (invertColors) {
        processedImage = img.invert(processedImage);
      }

      // 밝기/대비 조절
      // brightness: -1.0 ~ 1.0 범위를 -100 ~ 100 범위로 변환
      // contrast: 0.5 ~ 2.0 범위를 0 ~ 200 범위로 변환
      final adjustedImage = img.adjustColor(
        processedImage,
        brightness: (brightness * 100).toInt(),
        contrast: (contrast * 100).toInt(),
      );

      // PNG로 인코딩하여 반환
      return Uint8List.fromList(img.encodePng(adjustedImage));
    } catch (e) {
      print('이미지 변환 오류: $e');
      // 오류 발생 시 원본 데이터 반환
      return dicomImage.pixelData ?? Uint8List(0);
    }
  }

  /// 날짜 형식 변환 (YYYYMMDD -> YYYY-MM-DD)
  String _formatDate(String dateString) {
    if (dateString.length != 8) return dateString;

    try {
      final year = dateString.substring(0, 4);
      final month = dateString.substring(4, 6);
      final day = dateString.substring(6, 8);
      return '$year-$month-$day';
    } catch (e) {
      return dateString;
    }
  }

  /// DICOM 파일 내보내기 (새 파일 생성)
  Future<String?> exportDicomFile(DicomFile dicomFile, String fileName) async {
    try {
      // 원본 파일 가져오기
      final sourceFile = File(dicomFile.filePath);
      if (!await sourceFile.exists()) {
        throw Exception('원본 파일이 존재하지 않습니다');
      }

      // 출력 디렉토리 가져오기
      final directory = await getApplicationDocumentsDirectory();
      final outputPath = '${directory.path}/$fileName';

      // 파일 복사
      await sourceFile.copy(outputPath);

      return outputPath;
    } catch (e) {
      print('DICOM 파일 내보내기 오류: $e');
      return null;
    }
  }

  /// 파일 캐시 삭제
  Future<void> clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final cacheFiles = cacheDir.listSync();

      for (var file in cacheFiles) {
        if (file is File) {
          await file.delete();
        } else if (file is Directory) {
          await file.delete(recursive: true);
        }
      }
    } catch (e) {
      print('캐시 삭제 오류: $e');
    }
  }
}
