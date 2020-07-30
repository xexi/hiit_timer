import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/timer_creating/timer_creating_bloc.dart';
import '../../data/models/model_timer.dart';
import '../widgets/dialogs/dialog_timer_name.dart';
import '../widgets/views/view_timer_set.dart';

class TimerCreatingPage extends StatefulWidget {
  final TimerModel timer;

  TimerCreatingPage({this.timer});

  @override
  _TimerCreatingPageState createState() => _TimerCreatingPageState();
}

class _TimerCreatingPageState extends State<TimerCreatingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.timer == null ? 'Creating' : 'Editing'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () async {
              if (widget.timer == null) {
                final name = await TimerNameDialog.show(context);
                if (name != null) {
                  final timerSets =
                      context.bloc<TimerCreatingBloc>().state.timerSets;
                  final timer = TimerModel(name: name, timerSets: timerSets);
                  Navigator.pop(context, timer);
                }
              } else {
                final timer = context.bloc<TimerCreatingBloc>().state;
                Navigator.pop(context, timer);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: BlocBuilder<TimerCreatingBloc, TimerModel>(
                buildWhen: (previous, current) {
                  if (previous.timerSets.length != current.timerSets.length) {
                    return true;
                  } else {
                    var count = 0;
                    for (var i = 0; i < previous.timerSets.length; i++) {
                      if (previous.timerSets[i] != current.timerSets[i]) {
                        count++;
                        if (count >= 2) {
                          return true;
                        }
                      }
                    }
                    return false;
                  }
                },
                builder: (context, state) {
                  return ListView(
                    children: <Widget>[
                      for (var i = 0; i < state.timerSets.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: TimerSetView(
                            key: UniqueKey(),
                            timerSet: state.timerSets[i],
                            index: i,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FlatButton.icon(
                icon: Icon(Icons.add),
                label: Text('Add New Set'),
                onPressed: () {
                  context.bloc<TimerCreatingBloc>().add(TimerSetAdded());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
