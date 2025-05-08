// lib/utils/logger_setup.dart

import 'package:logger/logger.dart';

/// Global logger instance with pretty printing and debug level.
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,       // no stack trace lines
    errorMethodCount: 5,  // show up to 5 lines on error
    lineLength: 80,       // wrap lines at 80 chars
    colors: true,         // color-coded log output
    printEmojis: true,    // include emojis for log levels
    printTime: false,     // turn off timestamp
  ),
  level: Level.debug,     // default to debug output
);
