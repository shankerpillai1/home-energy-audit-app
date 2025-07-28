// Conditional import: if running on web, use the web version; otherwise mobile.
export 'credential_storage_mobile.dart'
    if (dart.library.html) 'credential_storage_web.dart';
