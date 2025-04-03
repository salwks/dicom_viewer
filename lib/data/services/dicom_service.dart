import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../models/dicom_file.dart';

class DicomService {
  /// 더미 DICOM 파일을 로드합니다.
  Future<DicomFile> loadDicomFile(String filePath) async {
    try {
      // 파일 존재 여부 확인
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('파일이 존재하지 않습니다: $filePath');
      }

      // 실제 파일이 아닌 더미 데이터 생성
      // 실제 구현에서는 파일을 파싱하여 태그 및 이미지 데이터를 추출해야 함

      // 더미 태그 데이터
      final dummyTags = <String, DicomTag>{
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
      };

      // 테스트용 이미지 크기
      final imageWidth = 512;
      final imageHeight = 512;

      // 더미 이미지 생성 (3개의 슬라이스 생성)
      final List<DicomImage> images = [];
      for (int i = 0; i < 3; i++) {
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

      // DICOM 파일 객체 생성
      return DicomFile(
        filePath: filePath,
        patientName: '홍길동',
        patientId: '12345678',
        studyDate: '2023-01-01',
        studyDescription: 'CT BRAIN',
        seriesDescription: 'AXIAL',
        modality: 'CT',
        images: images,
        tags: dummyTags,
        dateAdded: DateTime.now(),
      );
    } catch (e) {
      print('DICOM 파일 로드 오류: $e');
      throw Exception('DICOM 파일을 로드할 수 없습니다: $e');
    }
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

      // 밝기/대비 조절
      // brightness: -1.0 ~ 1.0 범위를 -100 ~ 100 범위로 변환
      // contrast: 0.5 ~ 2.0 범위를 0 ~ 200 범위로 변환
      final adjustedImage = img.adjustColor(
        image,
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
}
