class AppException implements Exception {
  final String message;
  final String? details;

  AppException(this.message, [this.details]);

  @override
  String toString() {
    if (details != null) return '$message: $details';
    return message;
  }
}

class DatabaseException extends AppException {
  DatabaseException(String message, [String? details])
      : super('Database Failure: $message', details);
}

class FlashcardNotFoundException extends AppException {
  FlashcardNotFoundException(int id)
      : super('Flashcard Not Found', 'No flashcard exists with ID: $id');
}

class NetworkException extends AppException {
  NetworkException(String message, [String? details])
      : super('Network Failure: $message', details);
}

