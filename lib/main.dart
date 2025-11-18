import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const BudgetBuddyApp());
}

// ============================================================================
// MAIN APP
// ============================================================================

class BudgetBuddyApp extends StatelessWidget {
  const BudgetBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget Buddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,

        // Typography Configuration
        textTheme: TextTheme(
          // Headers - Archivo
          displayLarge: GoogleFonts.archivo(
            fontSize: 57,
            fontWeight: FontWeight.bold,
          ),
          displayMedium: GoogleFonts.archivo(
            fontSize: 45,
            fontWeight: FontWeight.bold,
          ),
          displaySmall: GoogleFonts.archivo(
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
          headlineLarge: GoogleFonts.archivo(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: GoogleFonts.archivo(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          headlineSmall: GoogleFonts.archivo(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: GoogleFonts.archivo(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: GoogleFonts.archivo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: GoogleFonts.archivo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),

          // Body Text - Roboto Flex
          bodyLarge: GoogleFonts.robotoFlex(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          bodyMedium: GoogleFonts.robotoFlex(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          bodySmall: GoogleFonts.robotoFlex(
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),

          // Labels - Roboto Flex
          labelLarge: GoogleFonts.robotoFlex(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          labelMedium: GoogleFonts.robotoFlex(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          labelSmall: GoogleFonts.robotoFlex(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

enum TransactionType { income, expense }

enum Category {
  salary,
  business,
  other,
  food,
  transport,
  rent,
  utilities,
  entertainment,
  health,
  education,
  shopping,
  savings,
}

class Transaction {
  final String id;
  final double amount;
  final Category category;
  final TransactionType type;
  final DateTime date;
  final String note;

  Transaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'category': category.name,
    'type': type.name,
    'date': date.toIso8601String(),
    'note': note,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    amount: json['amount'],
    category: Category.values.firstWhere((e) => e.name == json['category']),
    type: TransactionType.values.firstWhere((e) => e.name == json['type']),
    date: DateTime.parse(json['date']),
    note: json['note'] ?? '',
  );
}

class Budget {
  final Category category;
  final double limit;

  Budget({required this.category, required this.limit});

  Map<String, dynamic> toJson() => {'category': category.name, 'limit': limit};

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
    category: Category.values.firstWhere((e) => e.name == json['category']),
    limit: json['limit'],
  );
}

// ============================================================================
// DATA MANAGER WITH PERSISTENT STORAGE
// ============================================================================

class DataManager extends ChangeNotifier {
  final List<Transaction> _transactions = [];
  final Map<Category, double> _budgets = {
    Category.food: 5000,
    Category.transport: 3000,
    Category.rent: 10000,
    Category.utilities: 2000,
    Category.entertainment: 2000,
    Category.shopping: 3000,
  };

  bool _isLoaded = false;

  List<Transaction> get transactions => List.unmodifiable(_transactions);
  Map<Category, double> get budgets => Map.unmodifiable(_budgets);
  bool get isLoaded => _isLoaded;

  DataManager() {
    _loadData();
  }

  // Load data from SharedPreferences
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load transactions
    final transactionsJson = prefs.getString('transactions');
    if (transactionsJson != null) {
      final List<dynamic> decoded = jsonDecode(transactionsJson);
      _transactions.clear();
      _transactions.addAll(
        decoded.map((json) => Transaction.fromJson(json)).toList(),
      );
    } else {
      // Add sample data only if no saved data exists
      _addSampleData();
    }

    // Load budgets
    final budgetsJson = prefs.getString('budgets');
    if (budgetsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(budgetsJson);
      _budgets.clear();
      decoded.forEach((key, value) {
        final category = Category.values.firstWhere((e) => e.name == key);
        _budgets[category] = value;
      });
    }

    _isLoaded = true;
    notifyListeners();
  }

  // Save data to SharedPreferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // Save transactions
    final transactionsJson = jsonEncode(
      _transactions.map((t) => t.toJson()).toList(),
    );
    await prefs.setString('transactions', transactionsJson);

    // Save budgets
    final budgetsJson = jsonEncode(
      _budgets.map((key, value) => MapEntry(key.name, value)),
    );
    await prefs.setString('budgets', budgetsJson);
  }

  void _addSampleData() {
    final now = DateTime.now();
    _transactions.addAll([
      Transaction(
        id: '1',
        amount: 15000,
        category: Category.salary,
        type: TransactionType.income,
        date: now.subtract(const Duration(days: 25)),
        note: 'Monthly salary',
      ),
      Transaction(
        id: '2',
        amount: 1200,
        category: Category.food,
        type: TransactionType.expense,
        date: now.subtract(const Duration(days: 2)),
        note: 'Grocery shopping',
      ),
      Transaction(
        id: '3',
        amount: 500,
        category: Category.transport,
        type: TransactionType.expense,
        date: now.subtract(const Duration(days: 1)),
        note: 'Matatu fare',
      ),
      Transaction(
        id: '4',
        amount: 8000,
        category: Category.rent,
        type: TransactionType.expense,
        date: now.subtract(const Duration(days: 5)),
        note: 'Monthly rent',
      ),
      Transaction(
        id: '5',
        amount: 800,
        category: Category.food,
        type: TransactionType.expense,
        date: now,
        note: 'Lunch with friends',
      ),
      Transaction(
        id: '6',
        amount: 300,
        category: Category.transport,
        type: TransactionType.expense,
        date: now,
        note: 'Uber',
      ),
    ]);
  }

  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
    _saveData();
    notifyListeners();
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    _saveData();
    notifyListeners();
  }

  void updateBudget(Category category, double limit) {
    _budgets[category] = limit;
    _saveData();
    notifyListeners();
  }

  // Clear all data (useful for demo reset)
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('transactions');
    await prefs.remove('budgets');
    _transactions.clear();
    _budgets.clear();
    _budgets.addAll({
      Category.food: 5000,
      Category.transport: 3000,
      Category.rent: 10000,
      Category.utilities: 2000,
      Category.entertainment: 2000,
      Category.shopping: 3000,
    });
    _addSampleData();
    _saveData();
    notifyListeners();
  }

  // Calculate total income for a period
  double getTotalIncome({DateTime? startDate, DateTime? endDate}) {
    return _transactions
        .where(
          (t) =>
              t.type == TransactionType.income &&
              (startDate == null || t.date.isAfter(startDate)) &&
              (endDate == null || t.date.isBefore(endDate)),
        )
        .fold(0, (sum, t) => sum + t.amount);
  }

  // Calculate total expenses for a period
  double getTotalExpenses({DateTime? startDate, DateTime? endDate}) {
    return _transactions
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              (startDate == null || t.date.isAfter(startDate)) &&
              (endDate == null || t.date.isBefore(endDate)),
        )
        .fold(0, (sum, t) => sum + t.amount);
  }

  // Get expenses by category
  double getCategoryExpense(
    Category category, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _transactions
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              t.category == category &&
              (startDate == null || t.date.isAfter(startDate)) &&
              (endDate == null || t.date.isBefore(endDate)),
        )
        .fold(0, (sum, t) => sum + t.amount);
  }

  // Get category budget percentage
  double getCategoryBudgetPercentage(Category category) {
    final spent = getCategoryExpense(category);
    final budget = _budgets[category] ?? 0;
    if (budget == 0) return 0;
    return (spent / budget * 100).clamp(0, 100);
  }
}

// ============================================================================
// MAIN NAVIGATION (Bottom Navigation Bar)
// ============================================================================

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final DataManager _dataManager = DataManager();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(dataManager: _dataManager),
      TransactionsScreen(dataManager: _dataManager),
      BudgetsScreen(dataManager: _dataManager),
      InsightsScreen(dataManager: _dataManager),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => _showAddTransactionSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
              backgroundColor: Colors.green.shade600,
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Budgets',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
        ],
      ),
    );
  }

  void _showAddTransactionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(dataManager: _dataManager),
    );
  }
}

// ============================================================================
// DASHBOARD SCREEN
// ============================================================================

class DashboardScreen extends StatelessWidget {
  final DataManager dataManager;

  const DashboardScreen({super.key, required this.dataManager});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: dataManager,
      builder: (context, child) {
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final totalIncome = dataManager.getTotalIncome(startDate: startOfMonth);
        final totalExpenses = dataManager.getTotalExpenses(
          startDate: startOfMonth,
        );
        final balance = totalIncome - totalExpenses;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Budget Buddy',
              style: GoogleFonts.archivo(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: Colors.green.shade100,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade600, Colors.green.shade800],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Balance',
                        style: GoogleFonts.robotoFlex(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ksh ${balance.toStringAsFixed(0)}',
                        style: GoogleFonts.robotoMono(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildBalanceItem(
                              'Income',
                              totalIncome,
                              Icons.arrow_downward,
                              Colors.green.shade200,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildBalanceItem(
                              'Expenses',
                              totalExpenses,
                              Icons.arrow_upward,
                              Colors.red.shade200,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section: Budget Overview
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget Overview',
                      style: GoogleFonts.archivo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(onPressed: () {}, child: const Text('See All')),
                  ],
                ),

                const SizedBox(height: 12),

                // Budget Categories
                ...dataManager.budgets.entries.take(4).map((entry) {
                  final spent = dataManager.getCategoryExpense(
                    entry.key,
                    startDate: startOfMonth,
                  );
                  final percentage = dataManager.getCategoryBudgetPercentage(
                    entry.key,
                  );
                  return _buildBudgetCard(
                    _getCategoryName(entry.key),
                    spent,
                    entry.value,
                    percentage,
                    _getCategoryIcon(entry.key),
                    _getCategoryColor(entry.key),
                  );
                }),

                const SizedBox(height: 24),

                // Recent Transactions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: GoogleFonts.archivo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(onPressed: () {}, child: const Text('See All')),
                  ],
                ),

                const SizedBox(height: 12),

                ...dataManager.transactions.reversed
                    .take(5)
                    .map((t) => _buildTransactionItem(t)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceItem(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.robotoFlex(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Ksh ${amount.toStringAsFixed(0)}',
            style: GoogleFonts.robotoMono(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(
    String category,
    double spent,
    double budget,
    double percentage,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: GoogleFonts.robotoFlex(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Ksh ${spent.toStringAsFixed(0)} / ${budget.toStringAsFixed(0)}',
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: GoogleFonts.robotoMono(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: percentage > 90 ? Colors.red : color,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                percentage > 90 ? Colors.red : color,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getCategoryColor(transaction.category).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCategoryIcon(transaction.category),
              color: _getCategoryColor(transaction.category),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getCategoryName(transaction.category),
                  style: GoogleFonts.robotoFlex(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (transaction.note.isNotEmpty)
                  Text(
                    transaction.note,
                    style: GoogleFonts.robotoFlex(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transaction.type == TransactionType.income ? '+' : '-'} Ksh ${transaction.amount.toStringAsFixed(0)}',
                style: GoogleFonts.robotoMono(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: transaction.type == TransactionType.income
                      ? Colors.green
                      : Colors.red,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
              Text(
                _formatDate(transaction.date),
                style: GoogleFonts.robotoFlex(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ============================================================================
// TRANSACTIONS SCREEN
// ============================================================================

class TransactionsScreen extends StatelessWidget {
  final DataManager dataManager;

  const TransactionsScreen({super.key, required this.dataManager});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: dataManager,
      builder: (context, child) {
        final transactions = dataManager.transactions.reversed.toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Transactions',
              style: GoogleFonts.archivo(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: Colors.green.shade100,
          ),
          body: transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions yet',
                        style: GoogleFonts.archivo(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add your first transaction',
                        style: GoogleFonts.robotoFlex(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return Dismissible(
                      key: Key(transaction.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        dataManager.deleteTransaction(transaction.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transaction deleted')),
                        );
                      },
                      child: _buildTransactionItem(transaction),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getCategoryColor(transaction.category).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(transaction.category),
              color: _getCategoryColor(transaction.category),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getCategoryName(transaction.category),
                  style: GoogleFonts.robotoFlex(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (transaction.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    transaction.note,
                    style: GoogleFonts.robotoFlex(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatDate(transaction.date),
                  style: GoogleFonts.robotoFlex(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${transaction.type == TransactionType.income ? '+' : '-'} Ksh ${transaction.amount.toStringAsFixed(0)}',
            style: GoogleFonts.robotoMono(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: transaction.type == TransactionType.income
                  ? Colors.green.shade600
                  : Colors.red.shade600,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ============================================================================
// ADD TRANSACTION SHEET (WITH FIXED DROPDOWN)
// ============================================================================

class AddTransactionSheet extends StatefulWidget {
  final DataManager dataManager;

  const AddTransactionSheet({super.key, required this.dataManager});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  Category _category = Category.food;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: double.parse(_amountController.text),
        category: _category,
        type: _type,
        date: DateTime.now(),
        note: _noteController.text,
      );

      widget.dataManager.addTransaction(transaction);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Add Transaction',
                style: GoogleFonts.archivo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Transaction Type Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _type = TransactionType.expense;
                          _category = Category.food;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _type == TransactionType.expense
                                ? Colors.red.shade600
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Expense',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.robotoFlex(
                              color: _type == TransactionType.expense
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _type = TransactionType.income;
                          _category = Category.salary;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _type == TransactionType.income
                                ? Colors.green.shade600
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Income',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.robotoFlex(
                              color: _type == TransactionType.income
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Amount Field
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (Ksh)',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                style: GoogleFonts.robotoMono(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Category Dropdown (FIXED)
              DropdownButtonFormField<Category>(
                value: _category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: _getCategories().map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          size: 20,
                          color: _getCategoryColor(category),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _getCategoryName(category),
                          style: GoogleFonts.robotoFlex(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),

              const SizedBox(height: 20),

              // Note Field
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Note (Optional)',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                style: GoogleFonts.robotoFlex(),
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _type == TransactionType.income
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Add Transaction',
                  style: GoogleFonts.robotoFlex(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Category> _getCategories() {
    if (_type == TransactionType.income) {
      return [Category.salary, Category.business, Category.other];
    } else {
      return [
        Category.food,
        Category.transport,
        Category.rent,
        Category.utilities,
        Category.entertainment,
        Category.health,
        Category.education,
        Category.shopping,
        Category.savings,
      ];
    }
  }
}

// ============================================================================
// BUDGETS SCREEN
// ============================================================================

class BudgetsScreen extends StatelessWidget {
  final DataManager dataManager;

  const BudgetsScreen({super.key, required this.dataManager});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: dataManager,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Budgets',
              style: GoogleFonts.archivo(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: Colors.green.shade100,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Set monthly budget limits for each category',
                style: GoogleFonts.robotoFlex(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ...dataManager.budgets.entries.map((entry) {
                final spent = dataManager.getCategoryExpense(entry.key);
                final percentage = dataManager.getCategoryBudgetPercentage(
                  entry.key,
                );
                return _buildBudgetCard(
                  context,
                  entry.key,
                  entry.value,
                  spent,
                  percentage,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    Category category,
    double budget,
    double spent,
    double percentage,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCategoryName(category),
                      style: GoogleFonts.robotoFlex(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Ksh ${spent.toStringAsFixed(0)} of ${budget.toStringAsFixed(0)}',
                      style: GoogleFonts.robotoMono(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    _showEditBudgetDialog(context, category, budget),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                percentage > 90
                    ? Colors.red
                    : percentage > 70
                    ? Colors.orange
                    : _getCategoryColor(category),
              ),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}% used',
                style: GoogleFonts.robotoFlex(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Ksh ${(budget - spent).toStringAsFixed(0)} left',
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  color: percentage > 90 ? Colors.red : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditBudgetDialog(
    BuildContext context,
    Category category,
    double currentBudget,
  ) {
    final controller = TextEditingController(
      text: currentBudget.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit ${_getCategoryName(category)} Budget',
          style: GoogleFonts.archivo(),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Budget Amount (Ksh)',
            prefixIcon: Icon(Icons.attach_money),
          ),
          style: GoogleFonts.robotoMono(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newBudget = double.tryParse(controller.text);
              if (newBudget != null && newBudget > 0) {
                dataManager.updateBudget(category, newBudget);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// INSIGHTS SCREEN
// ============================================================================

class InsightsScreen extends StatelessWidget {
  final DataManager dataManager;

  const InsightsScreen({super.key, required this.dataManager});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: dataManager,
      builder: (context, child) {
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final totalIncome = dataManager.getTotalIncome(startDate: startOfMonth);
        final totalExpenses = dataManager.getTotalExpenses(
          startDate: startOfMonth,
        );

        // Calculate category breakdown
        final expensesByCategory = <Category, double>{};
        for (var category in Category.values) {
          final amount = dataManager.getCategoryExpense(
            category,
            startDate: startOfMonth,
          );
          if (amount > 0) {
            expensesByCategory[category] = amount;
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Insights',
              style: GoogleFonts.archivo(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: Colors.green.shade100,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Income',
                        'Ksh ${totalIncome.toStringAsFixed(0)}',
                        Icons.trending_up,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Total Expenses',
                        'Ksh ${totalExpenses.toStringAsFixed(0)}',
                        Icons.trending_down,
                        Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Spending by Category
                Text(
                  'Spending by Category',
                  style: GoogleFonts.archivo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // Simple bar chart visualization
                if (expensesByCategory.isNotEmpty)
                  ...expensesByCategory.entries.map((entry) {
                    final percentage = totalExpenses > 0
                        ? (entry.value / totalExpenses * 100)
                        : 0.0;
                    return _buildCategoryBar(
                      _getCategoryName(entry.key),
                      entry.value,
                      percentage,
                      _getCategoryIcon(entry.key),
                      _getCategoryColor(entry.key),
                    );
                  })
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No expenses this month',
                        style: GoogleFonts.robotoFlex(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Insights
                Text(
                  'Key Insights',
                  style: GoogleFonts.archivo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                _buildInsightCard(
                  'Savings Rate',
                  totalIncome > 0
                      ? '${((totalIncome - totalExpenses) / totalIncome * 100).toStringAsFixed(1)}%'
                      : '0%',
                  'of your income saved this month',
                  Icons.savings,
                  Colors.blue,
                ),

                _buildInsightCard(
                  'Top Spending',
                  expensesByCategory.isNotEmpty
                      ? _getCategoryName(
                          expensesByCategory.entries
                              .reduce((a, b) => a.value > b.value ? a : b)
                              .key,
                        )
                      : 'None',
                  'Your biggest expense category',
                  Icons.emoji_events,
                  Colors.orange,
                ),

                _buildInsightCard(
                  'Daily Average',
                  'Ksh ${(totalExpenses / DateTime.now().day).toStringAsFixed(0)}',
                  'Average spending per day',
                  Icons.calendar_today,
                  Colors.purple,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.robotoFlex(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.robotoMono(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar(
    String category,
    double amount,
    double percentage,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category,
                  style: GoogleFonts.robotoFlex(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'Ksh ${amount.toStringAsFixed(0)}',
                style: GoogleFonts.robotoMono(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.robotoFlex(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.robotoMono(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.robotoFlex(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

String _getCategoryName(Category category) {
  switch (category) {
    case Category.salary:
      return 'Salary';
    case Category.business:
      return 'Business';
    case Category.other:
      return 'Other Income';
    case Category.food:
      return 'Food & Dining';
    case Category.transport:
      return 'Transport';
    case Category.rent:
      return 'Rent';
    case Category.utilities:
      return 'Utilities';
    case Category.entertainment:
      return 'Entertainment';
    case Category.health:
      return 'Health';
    case Category.education:
      return 'Education';
    case Category.shopping:
      return 'Shopping';
    case Category.savings:
      return 'Savings';
  }
}

IconData _getCategoryIcon(Category category) {
  switch (category) {
    case Category.salary:
      return Icons.work;
    case Category.business:
      return Icons.business_center;
    case Category.other:
      return Icons.more_horiz;
    case Category.food:
      return Icons.restaurant;
    case Category.transport:
      return Icons.directions_bus;
    case Category.rent:
      return Icons.home;
    case Category.utilities:
      return Icons.bolt;
    case Category.entertainment:
      return Icons.movie;
    case Category.health:
      return Icons.local_hospital;
    case Category.education:
      return Icons.school;
    case Category.shopping:
      return Icons.shopping_bag;
    case Category.savings:
      return Icons.savings;
  }
}

Color _getCategoryColor(Category category) {
  switch (category) {
    case Category.salary:
      return Colors.green;
    case Category.business:
      return Colors.blue;
    case Category.other:
      return Colors.grey;
    case Category.food:
      return Colors.orange;
    case Category.transport:
      return Colors.purple;
    case Category.rent:
      return Colors.brown;
    case Category.utilities:
      return Colors.yellow.shade700;
    case Category.entertainment:
      return Colors.pink;
    case Category.health:
      return Colors.red;
    case Category.education:
      return Colors.indigo;
    case Category.shopping:
      return Colors.teal;
    case Category.savings:
      return Colors.green;
  }
}
