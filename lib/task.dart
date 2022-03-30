import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Task {
  int taskId;
  String label;
  bool complete;

  Task({required this.taskId, required this.label, this.complete = false});
}

class TaskWidget extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;
  final VoidCallback onComplete;

  TaskWidget({required this.label,required this.onDelete,required this.onComplete});

  Widget _buildDissmissibleBackground(
    {required Color color,
      required IconData icon,
      FractionalOffset align = FractionalOffset.centerLeft}) =>
    new Container(
      height: 42.0,
      color: color,
      child: new Icon(icon, color: Colors.white70),
      alignment: align,
    );

  @override
  Widget build(BuildContext context) {
    return new Container(
      height: 42.0,
      child: new Dismissible(
        direction: DismissDirection.horizontal,
        child: new Align(
          alignment: FractionalOffset.centerLeft,
          child: new Padding(
            padding: new EdgeInsets.all(10.0), child: new Text(label))),
        key: new Key(label),
        background: _buildDissmissibleBackground(
          color: Colors.lime, icon: Icons.check),
        secondaryBackground: _buildDissmissibleBackground(
          color: Colors.red,
          icon: Icons.delete,
          align: FractionalOffset.centerRight),
        onDismissed: (direction) => direction == DismissDirection.startToEnd
          ? onComplete()
          : onDelete()));
  }
}
