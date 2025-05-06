import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
part 'database.g.dart';

class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 32)();
  TextColumn get content => text().named("body")();
  IntColumn get category =>
      integer().nullable().references(TodoCategory, #id)();
  DateTimeColumn get createAt => dateTime().nullable()();
}

class TodoCategory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text()();
}

@DriftDatabase(tables: [TodoItems, TodoCategory])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase();
  }
}

LazyDatabase driftDatabase() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final cachebase = (await getTemporaryDirectory()).path;

    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}

Future<void> backup() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final dbLocation = p.join(dbFolder.path, 'db.sqlite');
  final File file = File(dbLocation);
  Directory copyTo = Directory("storage/emulated/0/Sqlite Backup");

  if ((await copyTo.exists())) {
    //
  } else {
    print("not exist");
    await copyTo.create();
  }

  String newPath = "${copyTo.path}/db.sqlite";

  await file.copy(newPath);
}

Future<void> restore() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles();
  if (result != null) {
    final dbFolder = await getApplicationCacheDirectory();
    final dbLocation = p.join(dbFolder.path, 'db.sqlite');
    AppDatabase._openConnection().close();
    File file = File(result.files.single.path!);
    Uint8List updatedContent = await File(file.path).readAsBytes();
    await File(dbLocation).writeAsBytes(updatedContent, flush: true);
    SystemNavigator.pop();
  } else {
    // user cancel
  }
}
