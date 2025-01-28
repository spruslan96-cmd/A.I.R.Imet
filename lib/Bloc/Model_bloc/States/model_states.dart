// Bloc States
abstract class ModelState {}

class ModelInitial extends ModelState {}

class ModelChecking extends ModelState {}

class ModelExists extends ModelState {}

class ModelNotExists extends ModelState {}

class ModelDownloading extends ModelState {}

class ModelDownloaded extends ModelState {}

class ModelError extends ModelState {
  final String error;
  ModelError(this.error);
}
