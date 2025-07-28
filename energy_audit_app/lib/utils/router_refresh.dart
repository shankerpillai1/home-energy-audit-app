import 'dart:async';
import 'package:flutter/foundation.dart';

/// Notifier that calls notifyListeners() whenever the provided [stream] emits.
class RouterRefreshStream extends ChangeNotifier {
  final Stream _stream;
  late final StreamSubscription _sub;

  RouterRefreshStream(Stream<dynamic> stream) : _stream = stream {
    _sub = _stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
