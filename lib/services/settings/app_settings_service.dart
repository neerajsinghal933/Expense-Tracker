import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AppSettingsState {
  const AppSettingsState({this.fontFamily = 'inter'});

  final String fontFamily;

  AppSettingsState copyWith({String? fontFamily}) {
    return AppSettingsState(fontFamily: fontFamily ?? this.fontFamily);
  }

  Map<String, dynamic> toJson() => {'fontFamily': fontFamily};

  factory AppSettingsState.fromJson(Map<String, dynamic> json) {
    return AppSettingsState(
      fontFamily: json['fontFamily'] as String? ?? 'inter',
    );
  }
}

class AppSettingsController extends ChangeNotifier {
  AppSettingsState _state = const AppSettingsState();
  bool _loaded = false;

  AppSettingsState get state => _state;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final file = await _settingsFile();
      if (!await file.exists()) return;
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _state = AppSettingsState.fromJson(json);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setFontFamily(String fontFamily) async {
    _state = _state.copyWith(fontFamily: fontFamily);
    notifyListeners();
    final file = await _settingsFile();
    await file.writeAsString(jsonEncode(_state.toJson()));
  }

  Future<File> _settingsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/pulse_money_settings.json');
  }
}
