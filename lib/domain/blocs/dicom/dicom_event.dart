import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../presentation/widgets/dicom_viewer/painters.dart';
import '../../../presentation/widgets/annotation_tools/annotation_manager.dart';

abstract class DicomEvent extends Equatable {
  const DicomEvent();

  @override
  List<Object?> get props => [];
}

class LoadDicomFile extends DicomEvent {
  final String filePath;

  const LoadDicomFile(this.filePath);

  @override
  List<Object?> get props => [filePath];
}

class UpdateBrightness extends DicomEvent {
  final double brightness;

  const UpdateBrightness(this.brightness);

  @override
  List<Object?> get props => [brightness];
}

class UpdateContrast extends DicomEvent {
  final double contrast;

  const UpdateContrast(this.contrast);

  @override
  List<Object?> get props => [contrast];
}

class UpdateImageIndex extends DicomEvent {
  final int index;

  const UpdateImageIndex(this.index);

  @override
  List<Object?> get props => [index];
}

class SaveDicomSettings extends DicomEvent {
  final double brightness;
  final double contrast;

  const SaveDicomSettings({required this.brightness, required this.contrast});

  @override
  List<Object?> get props => [brightness, contrast];
}

class ToggleMeasurementMode extends DicomEvent {}

class ToggleAnnotationMode extends DicomEvent {}

class SelectMeasurementTool extends DicomEvent {
  final MeasurementType type;

  const SelectMeasurementTool(this.type);

  @override
  List<Object?> get props => [type];
}

class SelectAnnotationTool extends DicomEvent {
  final AnnotationToolType type;

  const SelectAnnotationTool(this.type);

  @override
  List<Object?> get props => [type];
}

class UpdateMeasurementColor extends DicomEvent {
  final Color color;

  const UpdateMeasurementColor(this.color);

  @override
  List<Object?> get props => [color];
}

class UpdateAnnotationColor extends DicomEvent {
  final Color color;

  const UpdateAnnotationColor(this.color);

  @override
  List<Object?> get props => [color];
}

class AddMeasurementPoint extends DicomEvent {
  final double x;
  final double y;

  const AddMeasurementPoint(this.x, this.y);

  @override
  List<Object?> get props => [x, y];
}

class ClearMeasurements extends DicomEvent {}

class AddAnnotation extends DicomEvent {
  final double x;
  final double y;
  final String text;
  final String? type;

  const AddAnnotation(this.x, this.y, this.text, {this.type});

  @override
  List<Object?> get props => [x, y, text, type];
}

class CompleteAnnotation extends DicomEvent {
  final String text;

  const CompleteAnnotation(this.text);

  @override
  List<Object?> get props => [text];
}

class CancelAnnotation extends DicomEvent {}

class ClearAnnotations extends DicomEvent {}

class RotateImage extends DicomEvent {
  final int degrees; // 90, 180, 270

  const RotateImage(this.degrees);

  @override
  List<Object?> get props => [degrees];
}

class FlipImage extends DicomEvent {
  final bool horizontal;

  const FlipImage({this.horizontal = true});

  @override
  List<Object?> get props => [horizontal];
}

class SaveMeasurements extends DicomEvent {}

class SaveAnnotations extends DicomEvent {}

class ExportImage extends DicomEvent {}
