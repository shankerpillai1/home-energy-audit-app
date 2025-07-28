import 'dart:html' as html;

/// Web implementation using window.localStorage
class CredentialStorage {
  Future<String?> read(String key) async {
    return html.window.localStorage[key];
  }

  Future<void> write(String key, String value) async {
    html.window.localStorage[key] = value;
  }
}
