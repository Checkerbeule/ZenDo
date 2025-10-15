import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zen_do/todo_list_page.dart';
import 'package:zen_do/model/todo.dart';
import 'package:zen_do/model/todo_list.dart';
import 'package:zen_do/model/todo_scope.dart';

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
  TodoList dailyToDoList = TodoList(TodoScope.daily);
  TodoList weeklyToDoList = TodoList(TodoScope.weekly);
  TodoList yearlyToDoList = TodoList(TodoScope.yearly);
  TodoList backlog = TodoList(TodoScope.backlog);

  void notify() {
    notifyListeners();
  }

}

class ZenDoHomePage extends StatelessWidget {
  const ZenDoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    ZenDoAppState state = context.watch<ZenDoAppState>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('ZenDo'),
      ),
      body: TodoListPage(list: state.dailyToDoList),
    );
  }
}
