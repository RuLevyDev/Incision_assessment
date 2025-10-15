class ValidationException implements Exception {
  ValidationException(this.messages);

  final Map<String, String> messages;

  @override
  String toString() => 'ValidationException($messages)';
}
