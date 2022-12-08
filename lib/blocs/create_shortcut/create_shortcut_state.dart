import 'package:equatable/equatable.dart';

abstract class CreateShortcutState extends Equatable {}

class CreateShortcutInitial extends CreateShortcutState {
  @override
  List<Object?> get props => [];
}

class CreateShortcutLoading extends CreateShortcutState {
  @override
  List<Object?> get props => [];
}

class CreateShortcutError extends CreateShortcutState {
  @override
  List<Object?> get props => [];
}

class CreateShortcutSuccess extends CreateShortcutState {
  @override
  List<Object?> get props => [];
}

class CreateShortcutValidationSuccess extends CreateShortcutState {
  @override
  List<Object?> get props => [];
}

class CreateShortcutConflicting extends CreateShortcutState {
  CreateShortcutConflicting(this.conflictingName);

  final String conflictingName;

  @override
  List<Object?> get props => [];
}
