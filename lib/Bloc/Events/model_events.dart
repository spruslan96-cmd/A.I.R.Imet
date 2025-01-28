// Bloc Events
abstract class ModelEvent {}

class CheckModelEvent extends ModelEvent {}

class DownloadModelEvent extends ModelEvent {
  final String modelSize;
  DownloadModelEvent(this.modelSize);
}
