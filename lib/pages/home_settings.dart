import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:epub_reader/providers/book_downloader/book_downloader.dart';
import 'package:epub_reader/providers/book_metadata/book_metadata.dart';
import 'package:epub_reader/providers/word_dictionary/word_dictionary.dart';
import 'package:epub_reader/widgets/clean_app_bar.dart';
import 'package:epub_reader/widgets/confirm_popup.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

import '../managers/settings_manager.dart';
import '../models/character.dart';
import '../utils/remove_leading_zeros.dart';
import '../widgets/input_popup.dart';
import '../widgets/settings_enum_dropdown.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class HomeSettings extends StatefulWidget {
  const HomeSettings({
    Key? key,
    required this.settingsManager,
  }) : super(key: key);

  final SettingsManager settingsManager;

  @override
  _HomeSettingsState createState() => _HomeSettingsState();
}

class _HomeSettingsState extends State<HomeSettings> {
  late final TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(
      text: removeLeadingZeros(
          widget.settingsManager.config.wordsPerPage.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localCharacters = widget.settingsManager.config.localCharacters;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CleanAppBar(
        title: 'Settings',
      ),
      body: Container(
        color: Theme.of(context).backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const SizedBox(
                  height: 80,
                ),
                SettingsEnumDropdown<BookMetadataEnum>(
                  settingName: 'Book metadata',
                  dropdownItems: BookMetadataEnum.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.name),
                        ),
                      )
                      .toList(),
                  value: widget.settingsManager.config.bookMetadata,
                  onChange: (value) {
                    setState(() {
                      widget.settingsManager.config.bookMetadata = value;
                    });
                    widget.settingsManager.saveConfig();
                  },
                ),
                SettingsEnumDropdown<BookDownloaderEnum>(
                  settingName: 'Book downloader',
                  dropdownItems: BookDownloaderEnum.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.name),
                        ),
                      )
                      .toList(),
                  value: widget.settingsManager.config.bookDownloader,
                  onChange: (value) {
                    setState(() {
                      widget.settingsManager.config.bookDownloader = value;
                    });
                    widget.settingsManager.saveConfig();
                  },
                ),
                SettingsEnumDropdown<WordDictionaryEnum>(
                  settingName: 'Word Dictionary',
                  dropdownItems: WordDictionaryEnum.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.name),
                        ),
                      )
                      .toList(),
                  value: widget.settingsManager.config.wordDictionary,
                  onChange: (value) {
                    setState(() {
                      widget.settingsManager.config.wordDictionary = value;
                    });
                    widget.settingsManager.saveConfig();
                  },
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.transparent,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                    color: Theme.of(context).primaryColor,
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _textEditingController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 5.0),
                      ),
                      labelText: 'Words per page',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final wordsPerPage = double.tryParse(val);
                      if (wordsPerPage != null) {
                        widget.settingsManager.config.wordsPerPage =
                            wordsPerPage;
                        widget.settingsManager.saveConfig();
                      }
                    },
                  ),
                ),
                SettingsEnumDropdown<ThemeMode>(
                  settingName: 'Theme',
                  dropdownItems: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text("None"),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text("Light"),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text("Dark"),
                    ),
                  ],
                  value: widget.settingsManager.config.themeMode,
                  onChange: (value) async {
                    setState(() {
                      widget.settingsManager.config.themeMode = value;
                    });
                    await widget.settingsManager.saveConfig();
                    Phoenix.rebirth(context);
                  },
                ),
                TextButton(
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Add a new characters list",
                    ),
                  ),
                  onPressed: () async {
                    final files = (await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['json'],
                    ))
                        ?.files;

                    if (files?.isEmpty ?? true) {
                      return;
                    }

                    final file = File(files!.single.path!);

                    final name = await inputPopup(
                      context,
                      "Enter the name of the character list",
                      "Name",
                    );

                    if (name?.isEmpty != false) {
                      return;
                    }

                    final characters =
                        (json.decode(await file.readAsString()) as List)
                            .map((e) => Character.fromJson(e))
                            .toList();

                    setState(() {
                      widget.settingsManager.config.localCharacters[name!] =
                          characters;
                    });
                    widget.settingsManager.saveConfig();
                  },
                ),
                Container(
                  height: 300,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(0),
                    itemCount: localCharacters.keys.length,
                    itemBuilder: (context, index) {
                      final key = localCharacters.keys.toList()[index];
                      return ListTile(
                        title: Text(key),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              localCharacters.remove(key);
                            });
                            widget.settingsManager.saveConfig();
                          },
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Export data",
                        ),
                      ),
                      onPressed: () async {
                        final tempDir = await getTemporaryDirectory();
                        final tempZipPath = p.join(tempDir.path, "data.zip");

                        final encoder = ZipFileEncoder();
                        await _zipDirectory(
                          encoder,
                          widget.settingsManager.directory,
                          filename: tempZipPath,
                        );

                        await FlutterFileDialog.saveFile(
                          params: SaveFileDialogParams(
                            fileName: "book-reader-data.zip",
                            mimeTypesFilter: ["application/zip"],
                            data: await File(tempZipPath).readAsBytes(),
                          ),
                        );
                      },
                    ),
                    TextButton(
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Delete data",
                        ),
                      ),
                      onPressed: () async {
                        // Delete the current data
                        final filesToDelete = await widget
                            .settingsManager.directory
                            .list()
                            .toList();
                        for (final file in filesToDelete) {
                          await file.delete(recursive: true);
                        }

                        Phoenix.rebirth(context);
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.red),
                      ),
                    ),
                    TextButton(
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Import data",
                        ),
                      ),
                      onPressed: () async {
                        if (await confirmPopup(
                              context,
                              "Warning",
                              "Are you sure you want to replace all your data?",
                            ) !=
                            true) {
                          return;
                        }

                        final files = (await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['zip'],
                        ))
                            ?.files;

                        if (files?.isEmpty ?? true) {
                          return;
                        }

                        final dataZipFilePath = files!.single.path!;

                        // Delete the current data
                        final filesToDelete = await widget
                            .settingsManager.directory
                            .list()
                            .toList();
                        for (final file in filesToDelete) {
                          await file.delete(recursive: true);
                        }

                        await extractFileToDisk(
                          dataZipFilePath,
                          widget.settingsManager.directory.path,
                        );

                        Phoenix.rebirth(context);
                      },
                    )
                  ],
                ),
              ]
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.all(8),
                      child: e,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _zipDirectory(ZipFileEncoder zipFileEncoder, Directory dir,
    {String? filename,
    int? level,
    bool followLinks = true,
    DateTime? modified}) async {
  final dirPath = dir.path;
  final zipPath = filename ?? '$dirPath.zip';
  level ??= ZipFileEncoder.GZIP;
  zipFileEncoder.create(zipPath, level: level, modified: modified);
  await zipFileEncoder.addDirectory(dir,
      includeDirName: false, level: level, followLinks: followLinks);
  zipFileEncoder.close();
}
