/// Base class for all repository-layer exceptions.
/// Callers catch this type (or its subtypes) instead of raw Drift exceptions.
sealed class RepositoryException implements Exception {
  const RepositoryException(this.message, {this.cause});

  final String message;

  /// The underlying exception from the data layer, if any.
  final Object? cause;

  @override
  String toString() => cause != null
      ? '$runtimeType: $message (caused by: $cause)'
      : '$runtimeType: $message';
}

/// Thrown when an INSERT fails (e.g. constraint violation).
final class TransactionInsertException extends RepositoryException {
  const TransactionInsertException(super.message, {super.cause});
}

/// Thrown when an UPDATE fails or no row was matched.
final class TransactionUpdateException extends RepositoryException {
  const TransactionUpdateException(super.message, {super.cause});
}

/// Thrown when a DELETE fails.
final class TransactionDeleteException extends RepositoryException {
  const TransactionDeleteException(super.message, {super.cause});
}

/// Thrown when a read / query fails.
final class TransactionReadException extends RepositoryException {
  const TransactionReadException(super.message, {super.cause});
}
