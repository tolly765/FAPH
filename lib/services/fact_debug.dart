import 'dart:developer' as dev;

String dbg = "[FAPH] [DEBUG]";
String warn = "[FAPH] [WARNING]";
String err = "[FAPH] [ERROR]";

void dprint(message) {
  dev.log("\x1B[32m$dbg\x1B[0m $message");
}

void wprint(message) {
  dev.log("\x1B[33m$warn\x1B[0m $message");
}

void eprint(message) {
  dev.log("\x1B[31m$err\x1B[0m $message");
}
