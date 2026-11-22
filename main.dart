import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NotesPage(),
    );
  }
}

class _Note {
  _Note({required this.id, required this.text});

  final int id;
  String text;
  bool isImportant = false;
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _controller = TextEditingController();

  final List<_Note> _notes = [];

  int _nextNoteId = 0;

  void _addNote() {
    String text = _controller.text.trim();

    if (text.isEmpty) return;

    setState(() {
      _notes.add(
        _Note(id: _nextNoteId++, text: text),
      );
      _controller.clear();
    });
  }

  void _deleteNote(_Note note) {
    setState(() {
      _notes.removeWhere((item) => item.id == note.id);
    });
  }

  Future<void> _viewNote(_Note note) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            note.isImportant ? 'Важная заметка' : 'Просмотр заметки',
          ),
          content: SingleChildScrollView(
            child: SelectableText(note.text),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  void _toggleImportant(_Note note) {
    setState(() {
      note.isImportant = !note.isImportant;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          note.isImportant
              ? 'Заметка отмечена как важная'
              : 'Статус важной заметки снят',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _editNote(_Note note) async {
    String editText = note.text;

    String? result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Редактировать заметку'),
          content: TextFormField(
            initialValue: note.text,
            autofocus: true,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Введите новый текст...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              editText = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                if (editText.trim().isNotEmpty) {
                  Navigator.pop(
                    dialogContext,
                    editText.trim(),
                  );
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      note.text = result;
    });
  }

  Future<bool?> _confirmSwipe(
    _Note note,
    DismissDirection direction,
  ) async {
    if (direction == DismissDirection.endToStart) {
      return true;
    }

    if (direction == DismissDirection.startToEnd) {
      if (note.isImportant) {
        setState(() {
          note.isImportant = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заметка снова обычная'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      return false;
    }

    return false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        title: const Text(
          'Мои заметки',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Напишите заметку...',
                prefixIcon: const Icon(Icons.edit_note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: (_) => _addNote(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addNote,
                icon: const Icon(Icons.save),
                label: const Text('Сохранить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Список заметок (${_notes.length})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _notes.isEmpty
                  ? const Center(
                      child: Text(
                        'Заметок пока нет.\nДобавьте свою первую заметку!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _notes.length,
                      itemBuilder: (context, index) {
                        final note = _notes[index];

                        return Dismissible(
                          key: ValueKey(note.id),
                          direction: DismissDirection.horizontal,

                          confirmDismiss: (direction) {
                            return _confirmSwipe(note, direction);
                          },

                          onDismissed: (direction) {
                            if (direction ==
                                DismissDirection.endToStart) {
                              setState(() {
                                _notes.removeWhere(
                                  (item) => item.id == note.id,
                                );
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Заметка удалена'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },

                          background: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            child: const Icon(
                              Icons.restore,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),

                          secondaryBackground: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),

                          child: GestureDetector(
                            onTap: () {
                              _viewNote(note);
                            },

                            onDoubleTap: () {
                              _toggleImportant(note);
                            },

                            onLongPress: () {
                              _editNote(note);
                            },

                            child: Card(
                              color: note.isImportant
                                  ? const Color(0xFFFFF3CD)
                                  : Colors.white,
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFEDE7F6),
                                  child: Icon(
                                    Icons.note_alt_outlined,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(note.text),
                                    ),
                                    if (note.isImportant)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      tooltip: 'Редактировать',
                                      onPressed: () {
                                        _editNote(note);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Удалить',
                                      onPressed: () {
                                        _deleteNote(note);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
