import "dart:convert";
import "dart:developer";
import "dart:io";

import "package:flutter/material.dart";

class NoteSummary extends StatefulWidget {
  final File selectedNoteFile;
  const NoteSummary({Key? key, required this.selectedNoteFile})
      : super(key: key);

  @override
  State<NoteSummary> createState() => _NoteSummaryState();
}

class _NoteSummaryState extends State<NoteSummary> {
  final TextEditingController noteInputController = TextEditingController();

  @override
  void dispose() {
    if (!saveFile(context)) {
      couldntSaveFileDialog(context);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String noteContent;
    return FutureBuilder(
      future: getNoteContent(widget.selectedNoteFile),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          noteContent = snapshot.data!;
          noteInputController.text = noteContent;
        } else {
          noteContent = '...';
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                  if (!saveFile(context)) {
                    couldntSaveFileDialog(context);
                  }
                }),
            title: Center(
                child: Text(widget.selectedNoteFile.uri.pathSegments.last)),
            actions: [
              const IconButton(onPressed: null, icon: Icon(Icons.menu_book)),
              IconButton(
                onPressed: () {
                  if (saveFile(context)) {
                    showDialog(
                        context: context,
                        builder: ((context) {
                          return const AlertDialog(
                            title: Text('Success'),
                            content: Text('note saved succesfully'),
                          );
                        }));
                  } else {
                    couldntSaveFileDialog(context);
                  }
                },
                icon: const Icon(Icons.save),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.only(left: 14.0, right: 14.0),
            child: TextField(
              controller: noteInputController,
              textAlignVertical: TextAlignVertical.top,
              expands: true,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                border: null,
                hintText: "start typing",
              ),
            ),
          ),
        );
      },
    );
  }

  Future<dynamic> couldntSaveFileDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: ((context) {
          return const AlertDialog(
            title: Text('Error'),
            content: Text('couldnt save note'),
          );
        }));
  }

  bool saveFile(BuildContext context) {
    var success = true;
    try {
      widget.selectedNoteFile
          .writeAsStringSync(noteInputController.text, encoding: utf8);
    } on FileSystemException catch (_, ex) {
      success = false;
      log(ex.toString());
    }

    return success;
  }

  Future<String> getNoteContent(File noteFile) {
    return noteFile.readAsString();
  }
}
