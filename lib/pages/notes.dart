import "dart:io";
import "package:flutter/material.dart";
import "package:path_provider/path_provider.dart";
import "package:notofl/pages/note_summary.dart";

class Notes extends StatefulWidget {
  final String selectedDir;
  const Notes({Key? key, required this.selectedDir}) : super(key: key);

  @override
  State<Notes> createState() => _NotesState();
}

class _NotesState extends State<Notes> {
  late Future futureResult;
  var noteTitles = <File>[];
  final TextEditingController noteNameController = TextEditingController();

  @override
  void initState() {
    futureResult = getFileNames(widget.selectedDir);
    checkOrCreateFolder();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: futureResult,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          noteTitles = snapshot.data;
          noteTitles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        }

        return Scaffold(
          appBar: AppBar(
            title: Center(child: Text(widget.selectedDir)),
            actions: const [
              IconButton(onPressed: null, icon: Icon(Icons.bar_chart_rounded)),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.only(left: 21.0, right: 21.0),
            child: ListView.builder(
              itemCount: noteTitles.length,
              physics: const BouncingScrollPhysics(
                  decelerationRate: ScrollDecelerationRate.normal),
              itemBuilder: (context, index) => Container(
                padding: const EdgeInsets.all(2),
                child: ListTile(
                  title: Text(noteTitles[index].uri.pathSegments.last),
                  subtitle: Text(noteTitles[index].lastModifiedSync().toString().substring(0, 19)),
                  trailing: IconButton(
                    onPressed: () {
                      noteTitles[index].deleteSync();
                      setState(() {
                        noteTitles.remove(noteTitles[index]);
                      });
                    },
                    icon: const Icon(Icons.delete)
                  ),
                  onTap: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NoteSummary(
                                selectedNoteFile: noteTitles[index])));
                    setState(() {
                      noteTitles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
                    });
                  },
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            shape: const CircleBorder(side: BorderSide.none),
            child: const Icon(Icons.note_add),
            onPressed: () {
              showNewNoteDialog(context);
            },
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  void showNewNoteDialog(BuildContext context) {
    Future(() => showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('New note'),
              content: TextField(
                autofocus: true,
                onSubmitted: (value) {
                  setState(() {
                    createNewNote(value.trim());
                  });
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => NoteSummary(selectedNoteFile: noteTitles.first)));
                  noteNameController.text = '';
                },
                controller: noteNameController,
                decoration: const InputDecoration(hintText: 'New note'),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      setState(() {
                        createNewNote(noteNameController.text.trim());
                      });
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => NoteSummary(selectedNoteFile: noteTitles.first)));
                      noteNameController.text = '';
                    },
                    child: const Text('Create')
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  }, 
                  child: const Text('Cancel')
                ),
              ],
            )));
  }

  Future<List<File>> getFileNames(String selectedDir) async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    var dir = Directory('${appDocumentsDir.path}/notofl/$selectedDir');
    final List<FileSystemEntity> entities = await dir.list().toList();
    final Iterable<File> files = entities.whereType<File>();

    // var noteNames = <String>[];
    // for (var element in files) {
    //   var fileName = element.uri.pathSegments.last;
    //   var dotPosition = fileName.indexOf('.');
    //   noteNames.add(fileName.substring(0, dotPosition));
    // }

    return files.toList();
  }

  Future<void> checkOrCreateFolder() async {
    await Directory('notofl/init/').create(recursive: true);
  }

  Future<void> createNewNote(String noteName) async {
    if (noteName.isEmpty || noteName.contains('.') || noteName.contains('/') || isNameInDirectory(noteName)) {
      return;
    }
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    var newNote = File(
        '${appDocumentsDir.path}/notofl/${widget.selectedDir}/$noteName.md');
    newNote.create();
    setState(() {
      noteTitles.insert(0, newNote);
    });
  }

  bool isNameInDirectory(String name) {
    for (var note in noteTitles) {
      if (note.uri.pathSegments.last == '$name.md') {
        return true;
      }
    }
    return false;
  }
}
