import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:yanita_music/core/error/failures.dart';

/// Contrato base para todos los casos de uso.
///
/// Implementa el principio de responsabilidad única (SRP):
/// cada UseCase encapsula exactamente una regla de negocio.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Parámetro nulo para casos de uso sin parámetros.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
