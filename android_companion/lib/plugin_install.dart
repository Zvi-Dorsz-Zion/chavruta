import 'package:chavruta_companion/version.dart';

/// הריפו שממנו משוחררים התוסף והמתקין. שחרור של `release.yml` תולה בו את
/// `chavruta-<semver>.otzplugin` תחת התג `v<גרסה מוצגת>`.
const String releaseRepo = 'Yehuda-Zakesh/chavruta';

/// הגרסה המוצגת, כפי ש-`release.yml` מתייג: בלי אפסים מיותרים בסוף —
/// `7.0.0` ← `7`, ‏`5.2.0` ← `5.2`.
String displayVersion(String semver) {
  final parts = semver.split('.');
  while (parts.length > 1 && parts.last == '0') {
    parts.removeLast();
  }
  return parts.join('.');
}

/// כתובת ההורדה של התוסף **מאותה גרסה** של המתאם — כמו במתקין של המחשב,
/// שמצרף את קובץ התוסף של השחרור שלו. גרסת המתאם והתוסף זהות תמיד
/// (`version_test.dart` אוכף זאת, ו-`release.yml` כותב את שתיהן).
String pluginDownloadUrl([String semver = companionVersion]) =>
    'https://github.com/$releaseRepo/releases/download/'
    'v${displayVersion(semver)}/chavruta-$semver.otzplugin';

/// קישור ההתקנה של אוצריא (`docs/deep_links.md` בריפו של אוצריא). אוצריא
/// מורידה את הקובץ ומציגה את ההרשאות לאישור; `overwrite` מעדכן גרסה קיימת
/// בלי לשאול אם לדרוס, אך אינו מדלג על אישור ההרשאות.
String pluginInstallUri([String semver = companionVersion]) => Uri(
  scheme: 'otzaria',
  host: 'plugin',
  path: '/install',
  queryParameters: {'url': pluginDownloadUrl(semver), 'overwrite': 'true'},
).toString();
