// Use conditional import to select the correct implementation
export 'platform_helper_io.dart'
    if (dart.library.html) 'platform_helper_stub.dart';
