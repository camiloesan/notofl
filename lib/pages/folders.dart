import "dart:developer";
import "dart:io";
import "package:flutter/material.dart";
import "package:notofl/pages/notes.dart";
import 'package:path_provider/path_provider.dart';

class Folders extends StatefulWidget {
  const Folders({super.key});

  @override
  State<Folders> createState() => _FoldersState();
}

class _FoldersState extends State<Folders> {
  late Future futureResult;
  final TextEditingController folderNameController = TextEditingController();

  @override
  void initState() {
    checkOrCreateFolder();
    futureResult = getFileNames();
    super.initState();
  }

  var folders = <FileSystemEntity>[];
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: futureResult,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          folders = snapshot.data;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Center(child: Text("Folders")),
          ),
          body: Padding(
            padding: const EdgeInsets.only(left: 21.0, right: 21.0),
            child: ListView.builder(
              itemCount: folders.length,
              physics: const BouncingScrollPhysics(
                  decelerationRate: ScrollDecelerationRate.normal),
              itemBuilder: (context, index) => Container(
                padding: const EdgeInsets.all(2),
                child: ListTile(
                  trailing: IconButton(
                      onPressed: () {
                        bool success = true;
                        try {
                          folders[index].deleteSync();
                        } catch (ex) {
                          log(ex.toString());
                          success = false;
                        }
                        if (!success) {
                          couldntDeleteFolderDialog(context);
                        } else {
                          setState(() {
                            folders.remove(folders[index]);
                          });
                        }
                      },
                      icon: const Icon(Icons.delete_forever)),
                  leading: const Icon(Icons.folder),
                  title: Text(folders[index].uri.pathSegments[
                      folders[index].uri.pathSegments.length - 2]),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Notes(
                              selectedDir: folders[index].uri.pathSegments[
                                  folders[index].uri.pathSegments.length - 2])),
                    );
                  },
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            shape: const CircleBorder(side: BorderSide.none),
            child: const Icon(Icons.add),
            onPressed: () {
              showNewFolderDialog(context);
            },
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  void showNewFolderDialog(BuildContext context) {
    Future(() => showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('New folder'),
              content: TextField(
                autofocus: true,
                onSubmitted: (value) {
                  createNewFolder(value.trim());
                  Navigator.pop(context);
                  folderNameController.text = '';
                },
                controller: folderNameController,
                decoration: const InputDecoration(hintText: 'New folder'),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    createNewFolder(folderNameController.text.trim());
                    Navigator.pop(context);
                    folderNameController.text = '';
                  },
                  child: const Text('Create'),
                ),
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel')),
              ],
            )));
  }

  Future<List<FileSystemEntity>> getFileNames() async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    var dir = Directory('${appDocumentsDir.path}/notofl');
    final List<FileSystemEntity> entities = await dir.list().toList();

    return entities;
  }

  Future<void> checkOrCreateFolder() async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    await Directory('${appDocumentsDir.path}/notofl/')
        .create(recursive: true);
  }

  Future<void> createNewFolder(String folderName) async {
    if (folderName.isEmpty ||
        folderName.contains('.') ||
        folderName.contains('/') ||
        folders.any((element) => element
            .uri.pathSegments[element.uri.pathSegments.length - 2]
            .contains(folderName))) {
      return;
    }
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    var newDir = await Directory('${appDocumentsDir.path}/notofl/$folderName/')
        .create(recursive: true);
    setState(() {
      folders.insert(0, newDir);
    });
  }

  Future<dynamic> couldntDeleteFolderDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: ((context) {
          return const AlertDialog(
            title: Text('Couldnt delete folder'),
            content: Text('Folder must be empty'),
          );
        }));
  }
}
