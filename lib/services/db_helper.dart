import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static const int _version = 4;
  static const String _dbName = 'pos.db';

  // Tables
  static const String tableCategories = 'categories';
  static const String tableUoms = 'uoms';
  static const String tableUsers = 'users';
  static const String tableProducts = 'products';
  static const String tableInventories = 'inventories';
  static const String tableAdjustments = 'adjustments';
  static const String tableTransactions = 'transactions';
  static const String tableTransactionDetails = 'transaction_details';
  static const String tableZReports = 'z_reports';
  static const String tableExpenses = 'expenses';
  static const String tablePaymentMethods = 'payment_methods';

  // Initialize DB
  static Future<Database> initDb() async {
    if (_db != null) return _db!;

    String path = join(await getDatabasesPath(), _dbName);

    _db = await openDatabase(
      path,
      version: _version,
      onCreate: (db, version) async {

        await db.execute('''
          CREATE TABLE $tableCategories(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE $tableUoms(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uom TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE $tableUsers(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT,
            password TEXT,
            fname TEXT,
            mname TEXT,
            lname TEXT,
            sex TEXT,
            role TEXT,
            timestamp TEXT
          )
          ''');


        // Create products table
        await db.execute('''
          CREATE TABLE $tableProducts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_code TEXT,
            barcode TEXT,
            category TEXT,
            name TEXT,
            unit TEXT,
            cost_price REAL,
            selling_price REAL,
            stock REAL DEFAULT 0,
            low_stock_level REAL,
            image_path TEXT
          )
        ''');

          // Create transactions table
        await db.execute('''
          CREATE TABLE $tableTransactions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            customer_name TEXT,
            quantity INTEGER,
            payment REAL,
            total REAL,
            payment_method TEXT DEFAULT 'Cash',
            timestamp TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE $tableTransactionDetails(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            transaction_id INTEGER,
            user_id INTEGER,
            product_id INTEGER,
            quantity REAL,
            cost_price REAL,
            selling_price REAL,
            line_total REAL,
            timestamp TEXT
          )
        ''');

        // await db.execute('''
        //   CREATE TABLE $tableInventories(
        //     id INTEGER PRIMARY KEY AUTOINCREMENT,
        //     product_id INTEGER,
        //     quantity REAL,
        //     timestamp TEXT
        //   )
        // ''');

        await db.execute('''
          CREATE TABLE $tableAdjustments(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            product_id INTEGER,
            action_status TEXT,
            quantity REAL,
            current_stock REAL,
            reason TEXT,
            timestamp TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE $tableZReports(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            business_date TEXT,
            total_sales REAL,
            total_payment REAL,
            total_qty REAL,
            tx_count INTEGER,
            avg_ticket REAL,
            closed_at TEXT,
            closed_by TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE $tableExpenses(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            amount REAL NOT NULL,
            description TEXT NOT NULL,
            category TEXT,
            date TEXT NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tablePaymentMethods(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            type TEXT DEFAULT 'cash',
            is_active INTEGER DEFAULT 1,
            created_at TEXT
          )
        ''');

        await _seedDefaultPaymentMethods(db);

      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $tableZReports(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              business_date TEXT,
              total_sales REAL,
              total_payment REAL,
              total_qty REAL,
              tx_count INTEGER,
              avg_ticket REAL,
              closed_at TEXT,
              closed_by TEXT
            )
          ''');
        }

        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $tableExpenses(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER,
              amount REAL NOT NULL,
              description TEXT NOT NULL,
              category TEXT,
              date TEXT NOT NULL,
              timestamp TEXT NOT NULL
            )
          ''');
        }

        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $tablePaymentMethods(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT UNIQUE NOT NULL,
              type TEXT DEFAULT 'cash',
              is_active INTEGER DEFAULT 1,
              created_at TEXT
            )
          ''');

          try {
            await db.execute(
              "ALTER TABLE $tableTransactions ADD COLUMN payment_method TEXT DEFAULT 'Cash'",
            );
          } catch (_) {
            // Column may already exist
          }

          await _seedDefaultPaymentMethods(db);
        }
      },
    );
    return _db!;
  }





  static Future<void> _seedDefaultPaymentMethods(Database db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tablePaymentMethods'),
    );
    if (count == null || count == 0) {
      final now = DateTime.now().toIso8601String();
      final defaults = [
        {'name': 'Cash', 'type': 'cash', 'is_active': 1, 'created_at': now},
        {'name': 'GCash', 'type': 'e-wallet', 'is_active': 1, 'created_at': now},
        {'name': 'Maya', 'type': 'e-wallet', 'is_active': 1, 'created_at': now},
        {'name': 'Bank Transfer', 'type': 'bank', 'is_active': 1, 'created_at': now},
        {'name': 'Credit/Debit Card', 'type': 'card', 'is_active': 1, 'created_at': now},
      ];
      for (final m in defaults) {
        await db.insert(
          tablePaymentMethods,
          m,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  // Insert transaction
  static Future<int> insertTransaction(Map<String, dynamic> row) async {
    final db = await initDb();
    return await db.insert(tableTransactions, row);
  }

  // Get all transactions
  static Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await initDb();
    return await db.query(tableTransactions, orderBy: 'timestamp DESC');
  }






}
