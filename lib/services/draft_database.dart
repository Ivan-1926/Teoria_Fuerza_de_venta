import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/credit_application_draft_model.dart';

/// Servicio de persistencia local SQLite para borradores de solicitudes (M5).
class DraftDatabase {
  static Database? _db;
  static const _tableName = 'credit_drafts';
  static const _dbName = 'pichincha_drafts.db';
  static const _dbVersion = 1;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            client_name TEXT NOT NULL,
            client_dni TEXT,
            client_phone TEXT,
            client_email TEXT,
            client_address TEXT,
            business_name TEXT,
            business_sector TEXT,
            business_address TEXT,
            monthly_income REAL DEFAULT 0,
            business_age_years INTEGER DEFAULT 0,
            amount REAL DEFAULT 0,
            term_months INTEGER DEFAULT 12,
            tea REAL DEFAULT 18.0,
            monthly_payment REAL,
            total_interest REAL,
            total_amount REAL,
            signature_base64 TEXT,
            status TEXT DEFAULT 'draft',
            officer_id TEXT,
            supabase_id TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Guarda o actualiza un borrador (upsert por `id`).
  Future<void> saveDraft(CreditApplicationDraftModel draft) async {
    final db = await database;
    final map = draft.toMap();

    // Ensure a local UUID exists
    if (map['id'] == null || (map['id'] as String).isEmpty) {
      map['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    }

    await db.insert(
      _tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Carga el borrador más reciente para un cliente (busca por client_dni).
  Future<CreditApplicationDraftModel?> loadLatestDraftByDni(String dni) async {
    final db = await database;
    final result = await db.query(
      _tableName,
      where: "client_dni = ? AND status = 'draft'",
      whereArgs: [dni],
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return CreditApplicationDraftModel.fromMap(result.first);
  }

  /// Lista todos los borradores pendientes (status = 'draft').
  Future<List<CreditApplicationDraftModel>> listDrafts() async {
    final db = await database;
    final result = await db.query(
      _tableName,
      where: "status = 'draft'",
      orderBy: 'updated_at DESC',
    );
    return result.map((m) => CreditApplicationDraftModel.fromMap(m)).toList();
  }

  /// Elimina un borrador por id.
  Future<void> deleteDraft(String id) async {
    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Marca un borrador como enviado (status = 'submitted').
  Future<void> markAsSubmitted(String id, {String? supabaseId}) async {
    final db = await database;
    await db.update(
      _tableName,
      {
        'status': 'submitted',
        'supabase_id': ?supabaseId,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
