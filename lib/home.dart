import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bloc/repeat_count/repeat_count_bloc.dart';
import 'bloc/timer/timer_bloc.dart';
import 'core/foreground_service.dart';
import 'core/prefs_keys.dart';
import 'core/service_locator.dart';
import 'core/utils.dart';
import 'presentation/widgets/bottom_sheet/bottom_sheet_presets.dart';
import 'presentation/widgets/bottom_sheet/bottom_sheet_repeat_count.dart';
import 'presentation/widgets/bottom_sheet/bottom_sheet_settings.dart';
import 'presentation/widgets/dialogs/dialog_review_prompt.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final prefs = sl<SharedPreferences>();
    final launchCount = prefs.getInt(PrefsKeys.launchCount) ?? 0;
    prefs.setInt(PrefsKeys.launchCount, launchCount + 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (prefs.getInt(PrefsKeys.launchCount) == 3) {
        ReviewPromptDialog.show(context);
      }
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  repeatCount(),
                  Flexible(child: timerName()),
                  resetButton(),
                ],
              ),
            ),
            Divider(),
            Container(
              height: 32,
              alignment: Alignment.center,
              child: tts(),
            ),
            Divider(),
            Expanded(child: remainingTime()),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FloatingActionButton(
            heroTag: 'fast_rewind',
            mini: true,
            child: Icon(Icons.fast_rewind, size: 20),
            onPressed: () {
              context.bloc<TimerBloc>().add(TimerRewound());
            },
          ),
          playPauseButton(),
          FloatingActionButton(
            heroTag: 'fast_forward',
            mini: true,
            child: Icon(Icons.fast_forward, size: 20),
            onPressed: () {
              context.bloc<TimerBloc>().add(TimerForwarded());
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.list),
              onPressed: () async {
                final timer = await PresetsBottomSheet.show(context);
                if (timer != null) {
                  context.bloc<TimerBloc>().add(TimerSelected(timer));
                }
              },
            ),
            BlocBuilder<TimerBloc, TimerState>(
              builder: (context, state) {
                if (state is TimerReady) {
                  return IconButton(
                    icon: Icon(Icons.settings),
                    onPressed: () {
                      SettingsBottomSheet.show(context);
                    },
                  );
                } else {
                  return IconButton(
                    icon: Icon(Icons.settings),
                    onPressed: null,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget repeatCount() {
    return BlocBuilder<TimerBloc, TimerState>(
      builder: (context, state) {
        if (state is TimerReady) {
          return BlocBuilder<RepeatCountBloc, int>(
            builder: (context, state) {
              return FlatButton.icon(
                onPressed: () async {
                  final repeatCount = await RepeatCountBottomSheet.show(
                    context,
                    currentRepeatCount: state == -1 ? 1 : state,
                  );
                  if (repeatCount != null) {
                    context
                        .bloc<RepeatCountBloc>()
                        .add(RepeatCountChanged(repeatCount));
                  }
                },
                icon: Icon(Icons.repeat),
                label: state == -1
                    ? Icon(Ionicons.ios_infinite)
                    : Text(
                        '${state}x',
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
              );
            },
          );
        } else {
          return BlocBuilder<RepeatCountBloc, int>(
            builder: (context, state) {
              return FlatButton.icon(
                onPressed: null,
                icon: Icon(Icons.repeat),
                label: state == -1
                    ? Icon(Ionicons.ios_infinite)
                    : Text(
                        '${state}x',
                        style: Theme.of(context)
                            .textTheme
                            .bodyText1
                            .copyWith(color: Colors.grey),
                      ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            },
          );
        }
      },
    );
  }

  Widget timerName() {
    return BlocBuilder<TimerBloc, TimerState>(
      builder: (context, state) {
        if (state is TimerInitial || state.name == null) {
          return Container();
        } else {
          return Text(
            state.name,
            style: Theme.of(context).textTheme.headline6,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );
        }
      },
    );
  }

  Widget tts() {
    return BlocBuilder<TimerBloc, TimerState>(
      builder: (context, state) {
        if (state is TimerInitial || state.tts == null) {
          return Container();
        } else {
          return Text(
            state.tts,
            style: Theme.of(context)
                .textTheme
                .headline6
                .copyWith(color: Theme.of(context).primaryColor),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }
      },
    );
  }

  Widget resetButton() {
    return FlatButton.icon(
      onPressed: () {
        ForegroundService.stop();
        context.bloc<TimerBloc>().add(TimerReset());
      },
      icon: Icon(Icons.refresh),
      label: Text('Reset'),
    );
  }

  Widget remainingTime() {
    return BlocBuilder<TimerBloc, TimerState>(
      builder: (context, state) {
        if (state is TimerInitial) {
          return Center(child: CircularProgressIndicator());
        } else if (state is TimerFinish) {
          return Center(
            child: Text(
              'Done!',
              style: Theme.of(context).textTheme.headline1.copyWith(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          );
        } else if (state is TimerFailure) {
          return Center(
            child: Text(state.message),
          );
        } else {
          return Center(
            child: Text(
              formatDuration(state.remainingTime),
              style: Theme.of(context).textTheme.headline1.copyWith(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 1,
            ),
          );
        }
      },
    );
  }

  Widget playPauseButton() {
    return BlocListener<TimerBloc, TimerState>(
      listener: (context, state) {
        if (state is TimerInitial) {
          _controller.reverse();
        } else if (state is TimerReady) {
          _controller.reverse();
        } else if (state is TimerRunning) {
          _controller.forward();
        } else if (state is TimerPause) {
          _controller.reverse();
        } else if (state is TimerFinish) {
          _controller.reverse();
        } else if (state is TimerFailure) {
          _controller.reverse();
        }
      },
      child: FloatingActionButton(
        heroTag: 'play_pause',
        child: AnimatedIcon(
          icon: AnimatedIcons.play_pause,
          progress: _controller,
        ),
        onPressed: () {
          final currentState = context.bloc<TimerBloc>().state;
          if (currentState is TimerRunning) {
            context.bloc<TimerBloc>().add(TimerPaused());
          } else if (currentState is TimerReady) {
            context.bloc<TimerBloc>().add(TimerStarted());
          } else if (currentState is TimerPause) {
            ForegroundService.resume();
            context.bloc<TimerBloc>().add(TimerResumed());
          } else if (currentState is TimerFinish) {
            context.bloc<TimerBloc>().add(TimerStarted());
          }
        },
      ),
    );
  }
}
