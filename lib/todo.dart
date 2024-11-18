import 'package:flutter/material.dart';

class Todo {
  String title;
  final DateTime date;
  String? memo;
  TimeOfDay? alarmTime;
  String? repeat;
  bool isDone;
  List<DateTime>? futureDates;
  List<String> repeatDays;

  Todo({
    required this.title,
    required this.date,
    this.memo,
    this.alarmTime,
    this.repeat,
    this.isDone = false,
    this.futureDates,
    this.repeatDays = const [],
  });
}

class TodoPage extends StatefulWidget {
  final DateTime selectedDate;
  final Function(Todo) onTodoAdded;
  final Function(Todo) onTodoRemoved;
  final Function(List<Todo>) onTodoListChanged;

  TodoPage({
    required this.selectedDate,
    required this.onTodoAdded,
    required this.onTodoRemoved,
    required this.onTodoListChanged,
  });

  @override
  _TodoPageState createState() => _TodoPageState();
}
class _TodoPageState extends State<TodoPage> {
  final List<Todo> _todoList = [];

  void _updateTodoList() {
    widget.onTodoListChanged(_todoList);
    // MyHomePage의 상태 업데이트
    setState(() {}); // 현재 위젯의 상태만 업데이트
  }

  List<Todo> _getEventsForDay(DateTime day) {
    return _todoList.where((todo) =>
    isSameDay(todo.date, day) ||
        (todo.futureDates?.any((futureDate) => isSameDay(futureDate, day)) ?? false)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTodoList = _todoList.where((todo) =>
        isSameDay(todo.date, widget.selectedDate)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Todo'),
      ),
      body: ListView.builder(
        itemCount: filteredTodoList.length,
        itemBuilder: (context, index) {
          final todo = filteredTodoList[index];
          return Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              setState(() {
                _todoList.remove(todo);
                _generateFutureDates(todo);
                _addFutureTodos(todo);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${todo.title} 삭제됨')),
              );
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: 20),
              color: Colors.red,
              child: Icon(Icons.delete, color: Colors.white),
            ),
            child: ListTile(
              title: Text(
                todo.title,
                style: TextStyle(
                  decoration: todo.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              trailing: _buildTrailingButtons(todo),
              onTap: () => _showTodoDetails(context, todo),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewTodoDialog(),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildTrailingButtons(Todo todo) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.edit, color: Colors.blue),
          onPressed: () => _showEditTitleDialog(context, todo),
        ),
        Checkbox(
          value: todo.isDone,
          onChanged: (bool? value) {
            setState(() {
              todo.isDone = value ?? false;
            });
          },
        ),
      ],
    );
  }

  void _showEditTitleDialog(BuildContext context, Todo todo) {
    TextEditingController _controller = TextEditingController(text: todo.title);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('타이틀 수정'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: '새로운 타이틀'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('수정'),
              onPressed: () {
                setState(() {
                  todo.title = _controller.text;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showTodoDetails(BuildContext context, Todo todo) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return FractionallySizedBox(
            heightFactor: 0.6,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(todo.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  _buildMemoField(todo),
                  SizedBox(height: 10),
                  _buildAlarmAndRepeatRow(todo),
                  SizedBox(height: 20),
                  _buildCompletionButton(todo),
                  Divider(),
                  _buildDeleteButton(todo),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildMemoField(Todo todo) {
    return TextFormField(
      initialValue: todo.memo,
      onChanged: (value) =>
          setState(() {
            todo.memo = value
                .trim()
                .isEmpty ? null : value;
          }),
      decoration: InputDecoration(
        hintText: '메모',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Widget _buildAlarmAndRepeatRow(Todo todo) {
    return Column(
      children: [
        Row(
          children: [
            _buildAlarmOption(todo),
            SizedBox(width: 10),
            _buildRepeatOption(todo),
          ],
        ),
        SizedBox(height: 10),
        _buildRepeatDaysOption(todo),
      ],
    );
  }

  Widget _buildAlarmOption(Todo todo) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectAlarmTime(context, todo),
        child: _buildOptionBox(
          icon: Icons.alarm,
          text: todo.alarmTime != null
              ? '${todo.alarmTime!.hour}:${todo.alarmTime!.minute.toString().padLeft(2, '0')}'
              : '알림 없음',
        ),
      ),
    );
  }

  Widget _buildRepeatOption(Todo todo) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectRepeatOption(context, todo),
        child: _buildOptionBox(
          icon: Icons.autorenew,
          text: todo.repeat ?? '반복 없음',
        ),
      ),
    );
  }

  Widget _buildRepeatDaysOption(Todo todo) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Wrap(
          spacing: 8.0,
          children: ['월', '화', '수', '목', '금', '토', '일'].map((day) {
            return FilterChip(
              label: Text(day),
              selected: todo.repeatDays.contains(day),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    todo.repeatDays.add(day);
                  } else {
                    todo.repeatDays.remove(day);
                  }
                  if (todo.repeatDays.length == 7) {
                    todo.repeat = '매일';
                  } else if (todo.repeatDays.isNotEmpty) {
                    todo.repeat = '매주';
                  } else {
                    todo.repeat = null;
                  }
                  _generateFutureDates(todo);
                });
                // 요일 선택 후 즉시 상태 업데이트
                _updateTodoList();
              },
            );
          }).toList(),
        );
      }
    );
  }

  void _selectAlarmTime(BuildContext context, Todo todo) async {
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: todo.alarmTime ?? TimeOfDay.now(),
    );

    if (selectedTime != null) {
      setState(() {
        todo.alarmTime = selectedTime;
        _generateFutureDates(todo);
      });
      _updateTodoList();
    }
  }

  void _selectRepeatOption(BuildContext context, Todo todo) async {
    String? selectedRepeat = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('반복 설정'),
          children: <Widget>[
            _buildRepeatOptionDialog('반복 안함'),
            _buildRepeatOptionDialog('매일'),
            _buildRepeatOptionDialog('매주'),
            _buildRepeatOptionDialog('매월'),
          ],
        );
      },
    );

    if (selectedRepeat != null) {
      setState(() {
        todo.repeat = selectedRepeat == '반복 안함' ? null : selectedRepeat;
        if (selectedRepeat == '매일') {
          todo.repeatDays = ['월', '화', '수', '목', '금', '토', '일'];
        } else if (selectedRepeat == '반복 안함') {
          todo.repeatDays = [];
        }
        _generateFutureDates(todo);
      });
      _updateTodoList();
    }
  }

  void _generateFutureDates(Todo todo) {
    if (todo.repeat == null || todo.alarmTime == null) {
      todo.futureDates = null;
      return;
    }

    List<Todo> futureTodos = [];
    DateTime currentDate = todo.date.add(Duration(days: 1)); // 다음 날부터 시작
    for (int i = 0; i < 52; i++) { // 1년치 생성
      switch (todo.repeat) {
        case '매일':
          currentDate = currentDate.add(Duration(days: 1));
          break;
        case '매주':
          do {
            currentDate = currentDate.add(Duration(days: 1));
          } while (!todo.repeatDays.contains(['월', '화', '수', '목', '금', '토', '일'][currentDate.weekday - 1]));
          break;
        case '매월':
          currentDate = DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
          break;
        default:
          return; // 알 수 없는 반복 패턴
      }
      Todo newTodo = Todo(
        title: todo.title,
        date: currentDate,
        memo: todo.memo,
        alarmTime: todo.alarmTime,
        repeat: todo.repeat,
        repeatDays: todo.repeatDays,
      );
      futureTodos.add(newTodo);
    }

    setState(() {
      _todoList.addAll(futureTodos);
    });
    _updateTodoList();
  }

  Widget _buildOptionBox({required IconData icon, required String text}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blue),
          SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildCompletionButton(Todo todo) {
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          todo.isDone = !todo.isDone;
        });
        Navigator.pop(context);
      },
      icon: Icon(todo.isDone ? Icons.check_circle : Icons.circle_outlined),
      label: Text(todo.isDone ? '완료 취소' : '완료로 표시'),
    );
  }

  Widget _buildDeleteButton(Todo todo) {
    return ElevatedButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('할 일 삭제'),
              content: Text('삭제하시겠습니까?'),
              actions: [
                TextButton(
                  child: Text('취소'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('삭제'),
                  onPressed: () {
                    setState(() {
                      _todoList.remove(todo);
                    });
                    _updateTodoList();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                ),
                if (todo.repeat != null)
                  TextButton(
                    child: Text('일정에서 전체 삭제'),
                    onPressed: () {
                      setState(() {
                        _todoList.removeWhere((t) =>
                        t.title == todo.title &&
                            t.repeat == todo.repeat &&
                            t.alarmTime == todo.alarmTime
                        );
                      });
                      _updateTodoList();
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            );
          },
        );
      },
      icon: Icon(Icons.delete, color: Colors.red),
      label: Text('삭제'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.withOpacity(0.8),
      ),
    );
  }


  SimpleDialogOption _buildRepeatOptionDialog(String option) {
    return SimpleDialogOption(
      onPressed: () {
        Navigator.pop(context, option);
      },
      child: Text(option),
    );
  }

  void _addNewTodoDialog() {
    TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('새 할 일 추가'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: '할 일 제목'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('추가'),
              onPressed: () {
                Todo newTodo = Todo(
                  title: _controller.text,
                  date: widget.selectedDate,
                );
                setState(() {
                  _todoList.add(newTodo);
                });
                _updateTodoList();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addFutureTodos(Todo originalTodo) {
    if (originalTodo.futureDates == null) return;

    for (DateTime futureDate in originalTodo.futureDates!) {
      Todo newTodo = Todo(
        title: originalTodo.title,
        date: futureDate,
        memo: originalTodo.memo,
        alarmTime: originalTodo.alarmTime,
        repeat: originalTodo.repeat,
      );
      setState(() {
        _todoList.add(newTodo);
      });
    }
    _updateTodoList();
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
