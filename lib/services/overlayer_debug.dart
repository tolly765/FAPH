import 'dart:developer' as dev;

String dbg = "[OVERLAYER] [DEBUG]   ";
String warn = "[OVERLAYER] [WARNING] ";
String err = "[OVERLAYER] [ERROR]   ";

void dprint(message) {
  dev.log("\x1B[36m$dbg\x1B[0m $message");
}

void wprint(message) {
  dev.log("\x1B[35m$warn\x1B[0m $message");
}

void eprint(message) {
  dev.log("\x1B[31m;1m$err\x1B[0m $message");
}
