import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Initialize FFI for Windows/Linux/macOS
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');

    // Bảng Categories: Lưu danh mục thu/chi
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
        icon TEXT,
        color TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Bảng Transactions: Giao dịch chi tiết
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
        notes TEXT,
        receipt_path TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');

    // Bảng Budgets: Ngân sách theo danh mục/tháng
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        month TEXT NOT NULL,
        limit_amount REAL NOT NULL,
        spent_amount REAL DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    // Bảng RecurringTransactions: Giao dịch định kỳ
    await db.execute('''
      CREATE TABLE recurring_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        category_id INTEGER NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        repeat_interval TEXT NOT NULL,
        next_run_date TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    // Bảng AI_Insights: Lưu kết quả phân tích AI
    await db.execute('''
      CREATE TABLE ai_insights (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        period TEXT NOT NULL,
        insight TEXT NOT NULL,
        prediction REAL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Bảng Savings Goals: Mục tiêu tiết kiệm
    await db.execute('''
      CREATE TABLE savings_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL DEFAULT 0,
        target_date TEXT,
        icon TEXT,
        color TEXT,
        is_completed INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Bảng Wallets: Ví/Tài khoản
    await db.execute('''
      CREATE TABLE wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL DEFAULT 0,
        icon TEXT,
        color TEXT,
        is_default INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Thêm ví mặc định
    await db.insert('wallets', {
      'name': 'Tiền mặt',
      'type': 'cash',
      'balance': 0,
      'icon': '💵',
      'color': '#4CAF50',
      'is_default': 1,
    });

    // Thêm dữ liệu mẫu - Danh mục Thu nhập
    await db.insert('categories', {
      'name': 'Lương',
      'type': 'income',
      'icon': '💰',
      'color': '#4CAF50',
    });
    await db.insert('categories', {
      'name': 'Thưởng',
      'type': 'income',
      'icon': '🎁',
      'color': '#8BC34A',
    });
    await db.insert('categories', {
      'name': 'Đầu tư',
      'type': 'income',
      'icon': '📈',
      'color': '#009688',
    });

    // Danh mục Chi tiêu mở rộng
    await db.insert('categories', {
      'name': 'Ăn uống',
      'type': 'expense',
      'icon': '🍲',
      'color': '#F44336',
    });
    await db.insert('categories', {
      'name': 'Di chuyển',
      'type': 'expense',
      'icon': '🚗',
      'color': '#2196F3',
    });
    await db.insert('categories', {
      'name': 'Mua sắm',
      'type': 'expense',
      'icon': '🛍️',
      'color': '#9C27B0',
    });
    await db.insert('categories', {
      'name': 'Giải trí',
      'type': 'expense',
      'icon': '🍿',
      'color': '#FF9800',
    });
    await db.insert('categories', {
      'name': 'Sức khỏe',
      'type': 'expense',
      'icon': '🏥',
      'color': '#E91E63',
    });
    await db.insert('categories', {
      'name': 'Giáo dục',
      'type': 'expense',
      'icon': '📚',
      'color': '#3F51B5',
    });
    await db.insert('categories', {
      'name': 'Tiết kiệm',
      'type': 'expense',
      'icon': '🐷',
      'color': '#00BCD4',
    });
    await db.insert('categories', {
      'name': 'Hóa đơn',
      'type': 'expense',
      'icon': '📄',
      'color': '#795548',
    });
    await db.insert('categories', {
      'name': 'Quà tặng',
      'type': 'expense',
      'icon': '🎀',
      'color': '#FF5722',
    });
    await db.insert('categories', {
      'name': 'Khác',
      'type': 'expense',
      'icon': '📦',
      'color': '#607D8B',
    });
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE recurring_transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount REAL NOT NULL,
          category_id INTEGER NOT NULL,
          description TEXT,
          type TEXT NOT NULL,
          repeat_interval TEXT NOT NULL,
          next_run_date TEXT NOT NULL,
          is_active INTEGER DEFAULT 1,
          FOREIGN KEY (category_id) REFERENCES categories(id)
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE transactions ADD COLUMN notes TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN receipt_path TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE savings_goals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          target_amount REAL NOT NULL,
          current_amount REAL DEFAULT 0,
          target_date TEXT,
          icon TEXT,
          color TEXT,
          is_completed INTEGER DEFAULT 0,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE wallets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          balance REAL DEFAULT 0,
          icon TEXT,
          color TEXT,
          is_default INTEGER DEFAULT 0,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Thêm ví mặc định cho người dùng hiện tại
      await db.insert('wallets', {
        'name': 'Tiền mặt',
        'type': 'cash',
        'balance': 0,
        'icon': '💵',
        'color': '#4CAF50',
        'is_default': 1,
      });
    }
    if (oldVersion < 6) {
      // Thêm các danh mục mới
      final existingCategories = await db.query('categories');
      final existingNames =
          existingCategories.map((c) => c['name'] as String).toSet();

      final newCategories = [
        {'name': 'Thưởng', 'type': 'income', 'icon': '🎁', 'color': '#8BC34A'},
        {'name': 'Đầu tư', 'type': 'income', 'icon': '📈', 'color': '#009688'},
        {
          'name': 'Giải trí',
          'type': 'expense',
          'icon': '🍿',
          'color': '#FF9800'
        },
        {
          'name': 'Sức khỏe',
          'type': 'expense',
          'icon': '🏥',
          'color': '#E91E63'
        },
        {
          'name': 'Giáo dục',
          'type': 'expense',
          'icon': '📚',
          'color': '#3F51B5'
        },
        {
          'name': 'Tiết kiệm',
          'type': 'expense',
          'icon': '🐷',
          'color': '#00BCD4'
        },
        {
          'name': 'Hóa đơn',
          'type': 'expense',
          'icon': '📄',
          'color': '#795548'
        },
        {
          'name': 'Quà tặng',
          'type': 'expense',
          'icon': '🎀',
          'color': '#FF5722'
        },
        {'name': 'Khác', 'type': 'expense', 'icon': '📦', 'color': '#607D8B'},
      ];

      for (final cat in newCategories) {
        if (!existingNames.contains(cat['name'])) {
          await db.insert('categories', cat);
        }
      }
    }
  }
}
