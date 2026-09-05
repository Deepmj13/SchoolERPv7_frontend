import 'dart:io';

String? networkErrorMessage(Object error) {
  if (error is SocketException) {
    return 'Cannot connect to the server. Please check your internet connection or try again later.';
  }
  return null;
}