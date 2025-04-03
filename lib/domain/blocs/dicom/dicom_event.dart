import 'package:equatable/equatable.dart';

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

  const AddAnnotation(this.x, this.y, this.text);

  @override
  List<Object?> get props => [x, y, text];
}

class ClearAnnotations extends DicomEvent {}
