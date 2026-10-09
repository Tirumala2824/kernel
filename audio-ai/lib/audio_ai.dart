/// Kernel on-device acoustic scan engine.
///
/// The only public entry point is [NativeScanEngine], an implementation of
/// the contracts `ScanEngine`. The pigeon bridge and mapping are internal.
library;

export 'src/native_scan_engine.dart' show NativeScanEngine;
