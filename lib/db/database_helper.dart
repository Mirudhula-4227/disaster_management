import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/report.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sos_mesh.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE reports(
            id TEXT PRIMARY KEY,
            description TEXT NOT NULL,
            category TEXT NOT NULL,
            people_affected INTEGER NOT NULL,
            vulnerable_people INTEGER NOT NULL,
            situation TEXT NOT NULL,
            assistance TEXT NOT NULL,
            user_selected_severity TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            status TEXT NOT NULL,
            priority_score REAL,
            final_severity TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertReport(Report report) async {
    final db = await database;
    await db.insert(
      'reports',
      report.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Report>> getAllReports() async {
    final db = await database;
    final maps = await db.query('reports', orderBy: 'created_at DESC');
    return maps.map((m) => Report.fromMap(m)).toList();
  }

  Future<List<Report>> getReportsByStatus(String status) async {
    final db = await database;
    final maps = await db.query(
      'reports',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'priority_score DESC, created_at ASC',
    );
    return maps.map((m) => Report.fromMap(m)).toList();
  }

  Future<List<Report>> getUnsyncedReports() async {
    final db = await database;
    final maps = await db.query(
      'reports',
      where: 'status != ?',
      whereArgs: ['synced'],
      orderBy: 'priority_score DESC, created_at ASC',
    );
    return maps.map((m) => Report.fromMap(m)).toList();
  }

  Future<List<String>> filterUnknownIds(List<String> incomingIds) async {
    final db = await database;
    final existing = await db.query('reports', columns: ['id']);
    final existingIds = existing.map((r) => r['id'] as String).toSet();
    return incomingIds.where((id) => !existingIds.contains(id)).toList();
  }

  Future<void> updateStatus(String id, String status) async {
    final db = await database;
    await db.update(
      'reports',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateScoring(
    String id,
    double priorityScore,
    String finalSeverity,
  ) async {
    final db = await database;
    await db.update(
      'reports',
      {
        'priority_score': priorityScore,
        'final_severity': finalSeverity,
        'status': 'synced',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Report?> getReportById(String id) async {
    final db = await database;
    final maps = await db.query('reports', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Report.fromMap(maps.first);
  }
}
