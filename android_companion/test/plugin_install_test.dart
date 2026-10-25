import 'package:chavruta_android/plugin_install.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('הגרסה המוצגת מוותרת על כל האפסים בסוף, כמו התגים של release.yml', () {
    expect(displayVersion('7.0.0'), '7');
    expect(displayVersion('5.2.0'), '5.2');
    expect(displayVersion('5.2.1'), '5.2.1');
    expect(displayVersion('10.0.0'), '10');
    expect(displayVersion('0.0.0'), '0');
  });

  test('כתובת ההורדה מתאימה לשמות הקבצים בשחרורים', () {
    // השחרור v7 קיים ומכיל בדיוק את הקובץ הזה.
    expect(
      pluginDownloadUrl('7.0.0'),
      'https://github.com/Yehuda-Zakesh/chavruta/releases/download/'
      'v7/chavruta-7.0.0.otzplugin',
    );
    expect(
      pluginDownloadUrl('5.2.0'),
      'https://github.com/Yehuda-Zakesh/chavruta/releases/download/'
      'v5.2/chavruta-5.2.0.otzplugin',
    );
  });

  test('קישור ההתקנה הוא plugin/install עם הכתובת מקודדת', () {
    final uri = Uri.parse(pluginInstallUri('7.0.0'));
    expect(uri.scheme, 'otzaria');
    expect(uri.host, 'plugin');
    expect(uri.path, '/install');
    expect(uri.queryParameters['url'], pluginDownloadUrl('7.0.0'));
    expect(uri.queryParameters['overwrite'], 'true');
  });
}
