import 'dart:async';

/// Mixin para proveer un canal de estados en tiempo real a los repositorios.
mixin StatusStreamMixin {
  final _statusController = StreamController<String>.broadcast();

  /// Stream público para escuchar los cambios de estado.
  Stream<String> get statusStream => _statusController.stream;

  /// Envía un mensaje de estado al stream.
  void sendStatus(String message) {
    if (!_statusController.isClosed) {
      _statusController.add(message);
    }
  }

  /// Cierra el controlador de stream.
  void disposeStatus() {
    _statusController.close();
  }
}
