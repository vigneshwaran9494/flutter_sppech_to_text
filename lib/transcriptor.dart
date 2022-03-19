import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:testapp/languages.dart';
import 'package:testapp/recognizer.dart';
import 'package:testapp/task.dart';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class TranscriptorWidget extends StatefulWidget {
  final Language lang;

  TranscriptorWidget({required this.lang});

  @override
  _TranscriptorAppState createState() => new _TranscriptorAppState();
}

class _TranscriptorAppState extends State<TranscriptorWidget> {
  String transcription = '';

  bool authorized = false;

  bool isListening = false;

  List<Task> todos = [];

  bool get isNotEmpty => transcription != '';

  get numArchived => todos.where((t) => t.complete).length;
  Iterable<Task> get incompleteTasks => todos.where((t) => !t.complete);

  SpeechToText _speechToText = SpeechToText();

  @override
  void initState() {
    super.initState();
    _activateRecognition();
  }

  @override
  void dispose() {
    super.dispose();
    if (isListening) _cancelRecognitionHandler();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    List<Widget> blocks = [
      new Expanded(
          flex: 2,
          child: new ListView(
              children: incompleteTasks
                  .map((t) => _buildTaskWidgets(
                      task: t,
                      onDelete: () => _deleteTaskHandler(t),
                      onComplete: () => _completeTaskHandler(t)))
                  .toList())),
      _buildButtonBar(),
    ];
    if (isListening || transcription != '')
      blocks.insert(
          1,
          _buildTranscriptionBox(
              text: transcription,
              onCancel: _cancelRecognitionHandler,
              width: size.width - 20.0));
    return new Center(
        child: new Column(mainAxisSize: MainAxisSize.min, children: blocks));
  }

  void _saveTranscription() {
    if (transcription.isEmpty) return;
    setState(() {
      todos.add(new Task(
          taskId: new DateTime.now().millisecondsSinceEpoch,
          label: transcription));
      transcription = '';
    });
    _cancelRecognitionHandler();
  }

  void _doNothing() {}

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (result.recognizedWords.isEmpty) return;
    setState(() {
      transcription = result.recognizedWords;
    });
  }

  Future _startRecognition() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    //setState(() {});
  }

  Future _cancelRecognitionHandler() async {
    await _speechToText.stop();

    setState(() {
      transcription = '';
      isListening = false;
    });
  }

  Future _activateRecognition() async {
    final res = await _speechToText.initialize();
    setState(() => authorized = res);
  }

  void _deleteTaskHandler(Task t) {
    setState(() {
      todos.remove(t);
      _showStatus("cancelled");
    });
  }

  void _completeTaskHandler(Task completed) {
    setState(() {
      todos =
          todos.map((t) => completed == t ? (t..complete = true) : t).toList();
      _showStatus("completed");
    });
  }

  Widget _buildButtonBar() {
    List<Widget> buttons = [
      !isListening
          ? _buildIconButton(authorized ? Icons.mic : Icons.mic_off,
              authorized ? _startRecognition : _doNothing,
              color: Colors.white, fab: true)
          : _buildIconButton(
              Icons.add, isListening ? _saveTranscription : _doNothing,
              color: Colors.white,
              backgroundColor: Colors.greenAccent,
              fab: true),
    ];
    Row buttonBar = new Row(mainAxisSize: MainAxisSize.min, children: buttons);
    return buttonBar;
  }

  Widget _buildTranscriptionBox(
          {required String text,
          required VoidCallback onCancel,
          required double width}) =>
      new Container(
          width: width,
          color: Colors.grey.shade200,
          child: new Row(children: [
            new Expanded(
                child: new Padding(
                    padding: new EdgeInsets.all(8.0), child: new Text(text))),
            new IconButton(
                icon: new Icon(Icons.close, color: Colors.grey.shade600),
                onPressed: text != '' ? () => onCancel() : null),
          ]));

  Widget _buildIconButton(IconData icon, VoidCallback onPress,
      {Color color: Colors.grey,
      Color backgroundColor: Colors.pinkAccent,
      bool fab = false}) {
    return new Padding(
      padding: new EdgeInsets.all(12.0),
      child: fab
          ? new FloatingActionButton(
              child: new Icon(icon),
              onPressed: onPress,
              backgroundColor: backgroundColor)
          : new IconButton(
              icon: new Icon(icon, size: 32.0),
              color: color,
              onPressed: onPress),
    );
  }

  Widget _buildTaskWidgets(
      {required Task task,
      required VoidCallback onDelete,
      required VoidCallback onComplete}) {
    return new TaskWidget(
        label: task.label, onDelete: onDelete, onComplete: onComplete);
  }

  void _showStatus(String action) {
    final label = "Task $action : ${incompleteTasks.length} left "
        "/ ${numArchived} archived";
    Scaffold.of(context).showSnackBar(new SnackBar(content: new Text(label)));
  }
}
