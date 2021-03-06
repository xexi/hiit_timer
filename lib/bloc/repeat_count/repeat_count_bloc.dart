import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/prefs_keys.dart';
import '../../core/service_locator.dart';

part 'repeat_count_event.dart';

class RepeatCountBloc extends Bloc<RepeatCountEvent, int> {
  final prefs = sl<SharedPreferences>();

  RepeatCountBloc() : super(1) {
    add(RepeatCountInitialized());
  }

  @override
  Stream<int> mapEventToState(
    RepeatCountEvent event,
  ) async* {
    if (event is RepeatCountInitialized) {
      yield prefs.getInt(PrefsKeys.repeatCountKey) ?? 1;
    } else if (event is RepeatCountChanged) {
      prefs.setInt(PrefsKeys.repeatCountKey, event.repeatCount);
      yield event.repeatCount;
    }
  }
}
