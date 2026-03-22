import 'package:equatable/equatable.dart';

enum LogLevel { info, warning, error, debug }

class LogEntry extends Equatable {
  final int? id;
  final LogLevel level;
  final String message;
  final String? tag;
  final String? stackTrace;
  final DateTime createdAt;

  const LogEntry({
    this.id,
    required this.level,
    required this.message,
    this.tag,
    this.stackTrace,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, level, message, tag, stackTrace, createdAt];

  Map<String, dynamic> toMap() {
    return {
      'level': level.name,
      'message': message,
      'tag': tag,
      'stack_trace': stackTrace,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      id: map['id'] as int?,
      level: LogLevel.values.firstWhere((e) => e.name == map['level']),
      message: map['message'] as String,
      tag: map['tag'] as String?,
      stackTrace: map['stack_trace'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
