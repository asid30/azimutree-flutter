import 'dart:io';

import 'package:azimutree/data/database/azimutree_db.dart';
import 'package:azimutree/data/database/titik_ikat_dao.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseFactory factory;

  setUpAll(() {
    sqfliteFfiInit();
    factory = databaseFactoryFfi;
  });

  test(
    'migration v1 to v6 preserves data and removes obsolete anchor columns',
    () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'azimutree_migration_test_',
      );
      final path = p.join(temporaryDirectory.path, 'azimutree.db');
      var db = await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON');
          },
          onCreate: (database, version) async {
            await database.execute('''
            CREATE TABLE clusters (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              kodeCluster TEXT NOT NULL,
              namaPengukur TEXT,
              tanggalPengukuran INTEGER
            )
          ''');
            await database.execute('''
            CREATE TABLE plots (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              kodePlot INTEGER NOT NULL,
              idCluster INTEGER NOT NULL,
              latitude REAL NOT NULL,
              longitude REAL NOT NULL,
              altitude REAL,
              FOREIGN KEY (idCluster) REFERENCES clusters(id) ON DELETE CASCADE
            )
          ''');
            await database.execute('''
            CREATE TABLE trees (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              kodePohon INTEGER NOT NULL,
              plotId INTEGER NOT NULL,
              namaPohon TEXT,
              namaIlmiah TEXT,
              azimut REAL,
              jarakPusatM REAL,
              latitude REAL,
              longitude REAL,
              altitude REAL,
              keterangan TEXT,
              urlFoto TEXT,
              FOREIGN KEY (plotId) REFERENCES plots(id) ON DELETE CASCADE
            )
          ''');
            await database.insert('clusters', {
              'id': 1,
              'kodeCluster': 'CL-OLD',
            });
            await database.insert('plots', {
              'id': 1,
              'kodePlot': 1,
              'idCluster': 1,
              'latitude': -5.4,
              'longitude': 105.2,
            });
            await database.insert('trees', {
              'id': 1,
              'kodePohon': 1,
              'plotId': 1,
            });
          },
        ),
      );
      await db.close();

      db = await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 6,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON');
          },
          onUpgrade: AzimutreeDB.migrate,
        ),
      );

      expect(await db.query('clusters'), hasLength(1));
      expect(await db.query('plots'), hasLength(1));
      expect(await db.query('trees'), hasLength(1));
      final treeColumns = await db.rawQuery('PRAGMA table_info(trees)');
      expect(treeColumns.map((row) => row['name']), contains('inspected'));

      await db.insert(TitikIkatDao.tableName, {
        'idCluster': 1,
        'nama': 'Patok Lama',
        'latitude': -5.4,
        'longitude': 105.2,
      });
      expect(await db.query(TitikIkatDao.tableName), hasLength(1));

      final anchorColumns = await db.rawQuery(
        'PRAGMA table_info(${TitikIkatDao.tableName})',
      );
      final anchorColumnNames = anchorColumns.map((row) => row['name']);
      expect(anchorColumnNames, isNot(contains('jenis')));
      expect(anchorColumnNames, isNot(contains('azimutKePlot1')));
      expect(anchorColumnNames, isNot(contains('jarakKePlot1M')));
      expect(anchorColumnNames, contains('urlFoto'));

      await db.delete('clusters', where: 'id = ?', whereArgs: [1]);
      expect(await db.query(TitikIkatDao.tableName), isEmpty);
      await db.close();
      await temporaryDirectory.delete(recursive: true);
    },
  );
}
