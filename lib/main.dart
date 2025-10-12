import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zen_do/dailyToDoList.dart';
import 'package:zen_do/model/todo.dart';

void main() {
  runApp(const ZenDoApp());
}

class ZenDoApp extends StatelessWidget {
  const ZenDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ZenDoAppState(),
      child: MaterialApp(
        title: 'ZenDo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
        ),
        home: ZenDoHomePage(),
      ),
    );
  }
}

class ZenDoAppState extends ChangeNotifier {
  Set<ToDo> toDos = {};

  void addToDo(var todo) {
    toDos.add(todo);
    notifyListeners();
  }

  void removeTodo(var todo) {
    toDos.remove(todo);
    notifyListeners();
  }
}

class ZenDoHomePage extends StatelessWidget {
  const ZenDoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('ZenDo'),
      ),
      body: DailyToDoList(),
    );
  }
}
