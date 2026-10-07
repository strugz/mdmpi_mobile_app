/// A non-200 response from a backend endpoint, carrying enough detail to tell
/// an outage apart from a bug without reading the logs.
///
/// The repositories used to throw `Exception('Failed to load Client')` from
/// every endpoint and then re-wrap it in `Something went wrong. Please try
/// again: $e`, so a user saw a doubled exception naming the wrong resource and
/// no status code — a 502 from a dead upstream looked exactly like a parsing
/// bug in the app.
class BApiException implements Exception {
  /// What the app was trying to load, in words a user recognises, e.g.
  /// `requester list`.
  final String resource;

  /// The endpoint path, for the logs.
  final String endpoint;

  /// The HTTP status the server actually returned.
  final int statusCode;

  const BApiException(this.resource, this.endpoint, this.statusCode);

  /// True when the status says the server, not the request, is at fault.
  bool get isServerUnavailable => statusCode >= 500;

  /// A message safe to put in a snackbar.
  String get message {
    if (isServerUnavailable) {
      return 'The server is not responding, so the $resource could not be '
          'loaded. It should recover on its own — please try again later.';
    }
    return 'Could not load the $resource (HTTP $statusCode).';
  }

  @override
  String toString() => '$message [$endpoint → HTTP $statusCode]';
}
