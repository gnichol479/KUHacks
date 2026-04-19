import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AutoPayScope { off, all, friends }

@immutable
class AutoPaySettings {
  final AutoPayScope scope;
  final List<String> friendIds;
  final Map<String, String> friendNames;

  const AutoPaySettings.off()
      : scope = AutoPayScope.off,
        friendIds = const [],
        friendNames = const {};

  const AutoPaySettings.all()
      : scope = AutoPayScope.all,
        friendIds = const [],
        friendNames = const {};

  const AutoPaySettings.friends(this.friendIds, this.friendNames)
      : scope = AutoPayScope.friends;

  bool get isOn => scope != AutoPayScope.off;

  bool coversFriendId(String? id) {
    if (scope == AutoPayScope.all) return true;
    if (scope == AutoPayScope.friends) {
      return id != null && friendIds.contains(id);
    }
    return false;
  }

  String? nameFor(String id) => friendNames[id];

  @override
  bool operator ==(Object other) =>
      other is AutoPaySettings &&
      other.scope == scope &&
      listEquals(other.friendIds, friendIds) &&
      mapEquals(other.friendNames, friendNames);

  @override
  int get hashCode => Object.hash(
        scope,
        Object.hashAll(friendIds),
        Object.hashAll(friendNames.entries.map((e) => Object.hash(e.key, e.value))),
      );
}

class AutoPayService {
  AutoPayService._();
  static final AutoPayService instance = AutoPayService._();

  static const _kScope = 'auto_pay_scope';
  static const _kFriendIds = 'auto_pay_friend_ids';
  static const _kFriendNames = 'auto_pay_friend_names';

  final ValueNotifier<AutoPaySettings> notifier =
      ValueNotifier<AutoPaySettings>(const AutoPaySettings.off());

  bool _hydrated = false;

  Future<AutoPaySettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final scopeStr = prefs.getString(_kScope);
    AutoPaySettings settings;
    switch (scopeStr) {
      case 'all':
        settings = const AutoPaySettings.all();
        break;
      case 'friends':
        final idsRaw = prefs.getString(_kFriendIds);
        final namesRaw = prefs.getString(_kFriendNames);
        final ids = <String>[];
        final names = <String, String>{};
        if (idsRaw != null && idsRaw.isNotEmpty) {
          try {
            final decoded = jsonDecode(idsRaw);
            if (decoded is List) {
              for (final v in decoded) {
                if (v is String && v.isNotEmpty) ids.add(v);
              }
            }
          } catch (_) {}
        }
        if (namesRaw != null && namesRaw.isNotEmpty) {
          try {
            final decoded = jsonDecode(namesRaw);
            if (decoded is Map) {
              decoded.forEach((k, v) {
                if (k is String && v is String) names[k] = v;
              });
            }
          } catch (_) {}
        }
        if (ids.isEmpty) {
          settings = const AutoPaySettings.off();
        } else {
          settings = AutoPaySettings.friends(ids, names);
        }
        break;
      default:
        settings = const AutoPaySettings.off();
    }
    _hydrated = true;
    notifier.value = settings;
    return settings;
  }

  Future<AutoPaySettings> ensureLoaded() async {
    if (_hydrated) return notifier.value;
    return load();
  }

  Future<void> save(AutoPaySettings s) async {
    final prefs = await SharedPreferences.getInstance();
    switch (s.scope) {
      case AutoPayScope.off:
        await prefs.remove(_kScope);
        await prefs.remove(_kFriendIds);
        await prefs.remove(_kFriendNames);
        break;
      case AutoPayScope.all:
        await prefs.setString(_kScope, 'all');
        await prefs.remove(_kFriendIds);
        await prefs.remove(_kFriendNames);
        break;
      case AutoPayScope.friends:
        await prefs.setString(_kScope, 'friends');
        await prefs.setString(_kFriendIds, jsonEncode(s.friendIds));
        await prefs.setString(_kFriendNames, jsonEncode(s.friendNames));
        break;
    }
    _hydrated = true;
    notifier.value = s;
  }
}
