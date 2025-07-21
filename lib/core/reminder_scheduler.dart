// Conditional export for web/native
export 'reminder_scheduler_stub.dart'
    if (dart.library.io) 'reminder_scheduler_native.dart';
