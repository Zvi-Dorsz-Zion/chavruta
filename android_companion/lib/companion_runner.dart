import 'dart:io';

import 'package:chavruta_companion/config.dart';
import 'package:chavruta_companion/lan_transport.dart';
import 'package:chavruta_companion/local_api.dart';
import 'package:chavruta_companion/protocol.dart';
import 'package:chavruta_companion/sync_hub.dart';
import 'package:chavruta_companion/version.dart';
import 'package:flutter/foundation.dart';

import 'native.dart';

/// גודל מקסימלי לקובץ הלוג, כמו במתאם של המחשב.
const int maxLogBytes = 256 * 1024;

/// כמה שורות יומן נשמרות בזיכרון לתצוגה במסך.
const int maxLogLines = 400;

/// מריץ את המתאם בתוך האפליקציה — המקבילה של `bin/chavruta_companion.dart`.
///
/// ההבדלים מהמחשב: הקונפיג והיומן בתיקיית הנתונים של האפליקציה ולא ב-
/// `%LOCALAPPDATA%`, אין בדיקת חומת אש (אין כזו באנדרואיד), ושם המכשיר
/// נלקח מהגדרות הטלפון, כי `Platform.localHostname` מחזיר שם `localhost`.
class CompanionRunner extends ChangeNotifier {
  final List<String> lines = [];
  IOSink? _file;
  SyncHub? _hub;
  LocalApi? _api;
  bool _busy = false;

  /// למה ההפעלה האחרונה נכשלה, לתצוגה. `null` = לא נכשלה.
  String? startError;

  bool get running => _api != null;
  bool get busy => _busy;
  int? get port => _api?.port;

  /// אותו מצב ש-`/hello` מחזיר לתוסף.
  Map<String, Object?>? snapshot() => _hub?.snapshot();

  void log(String message) {
    lines.add('[${_clock()}] $message');
    if (lines.length > maxLogLines) {
      lines.removeRange(0, lines.length - maxLogLines);
    }
    try {
      _file?.writeln('[${DateTime.now().toIso8601String()}] $message');
    } catch (_) {
      // כתיבה לקובץ נכשלה — היומן במסך ממשיך.
    }
    notifyListeners();
  }

  Future<void> start() async {
    if (running || _busy) return;
    _busy = true;
    startError = null;
    notifyListeners();
    try {
      final dir = Directory(
        '${await Native.filesDir()}${Platform.pathSeparator}Chavruta',
      );
      await dir.create(recursive: true);
      await _openLogFile(dir);
      log('מתאם חברותא $companionVersion מתחיל (אנדרואיד)');

      final config = await CompanionConfig.load(storageDir: dir);
      if (config.deviceName.trim().isEmpty ||
          config.deviceName == 'localhost') {
        config.deviceName = await Native.deviceName();
        await config.save();
      }

      final transport = LanTransport(
        roomCodeProvider: () => config.roomCode,
        onLog: log,
      );
      final hub = SyncHub(config: config, transport: transport, onLog: log);
      final api = LocalApi(hub: hub, version: companionVersion, onLog: log);

      // כמו במחשב: בלי ה-API המקומי אין ערוץ אל התוסף, וכל הפורטים
      // תפוסים = כמעט תמיד מופע אחר של המתאם שכבר רץ.
      if (!await api.start()) {
        startError =
            'לא נמצא פורט פנוי בטווח $localApiFirstPort-$localApiLastPort';
        log('$startError — כנראה שהמתאם כבר רץ.');
        await hub.dispose();
        return;
      }

      await hub.start();
      _hub = hub;
      _api = api;
      // שירות החזית הוא מה שמונע מאנדרואיד להקפיא את האפליקציה כשעוברים
      // לאוצריא. בלעדיו הסנכרון נעצר שניות אחרי שהמסך הזה יורד לרקע.
      await Native.startService();
      log(
        config.isPaired
            ? 'מחובר לחברותא בשם "${config.deviceName}"'
            : 'לא מזווג — ממתין לקוד חברותא מהתוסף באוצריא',
      );
    } catch (e, stack) {
      startError = '$e';
      log('ההפעלה נכשלה: $e\n$stack');
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    final api = _api;
    final hub = _hub;
    if (api == null || hub == null || _busy) return;
    _busy = true;
    notifyListeners();
    try {
      log('המתאם נעצר');
      await api.dispose();
      await hub.dispose();
      await Native.stopService();
    } catch (e) {
      log('שגיאה בעצירה: $e');
    } finally {
      _api = null;
      _hub = null;
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _openLogFile(Directory dir) async {
    if (_file != null) return;
    try {
      final file = File('${dir.path}${Platform.pathSeparator}companion.log');
      final tooBig = await file.exists() && await file.length() > maxLogBytes;
      _file = file.openWrite(mode: tooBig ? FileMode.write : FileMode.append);
    } catch (_) {
      _file = null;
    }
  }

  static String _clock() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
  }
}
