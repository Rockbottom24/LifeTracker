import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/expense_tables.dart';

part 'expense_dao.g.dart';

@DriftAccessor(tables: [ExpenseCategoriesTable, ExpensesTable])
class ExpenseDao extends DatabaseAccessor<AppDatabase> with _$ExpenseDaoMixin {
  ExpenseDao(super.db);

  // ── Categories ─────────────────────────────────────────────────────────────

  Future<List<ExpenseCategoriesTableData>> getAllCategories() =>
      (select(expenseCategoriesTable)
            ..where((t) => t.isActive.equals(true) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Stream<List<ExpenseCategoriesTableData>> watchAllCategories() =>
      (select(expenseCategoriesTable)
            ..where((t) => t.isActive.equals(true) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  Future<ExpenseCategoriesTableData?> getCategoryById(int id) =>
      (select(expenseCategoriesTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertCategory(ExpenseCategoriesTableCompanion category) =>
      into(expenseCategoriesTable).insert(category);

  Future<bool> updateCategory(ExpenseCategoriesTableCompanion category) =>
      update(expenseCategoriesTable).replace(category);

  Future<void> softDeleteCategory(int id) =>
      (update(expenseCategoriesTable)..where((t) => t.id.equals(id)))
          .write(ExpenseCategoriesTableCompanion(
        deletedAt: Value(DateTime.now()),
        isActive: const Value(false),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ));

  // ── Expenses ────────────────────────────────────────────────────────────────

  Future<List<ExpensesTableData>> getAllExpenses() =>
      (select(expensesTable)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.spentAt)]))
          .get();

  Stream<List<ExpensesTableData>> watchAllExpenses() =>
      (select(expensesTable)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.spentAt)]))
          .watch();

  Future<List<ExpensesTableData>> getExpensesInRange(
      DateTime from, DateTime to) =>
      (select(expensesTable)
            ..where((t) =>
                t.deletedAt.isNull() &
                t.spentAt.isBiggerOrEqualValue(from) &
                t.spentAt.isSmallerThanValue(to))
            ..orderBy([(t) => OrderingTerm.desc(t.spentAt)]))
          .get();

  Stream<List<ExpensesTableData>> watchExpensesInRange(
      DateTime from, DateTime to) =>
      (select(expensesTable)
            ..where((t) =>
                t.deletedAt.isNull() &
                t.spentAt.isBiggerOrEqualValue(from) &
                t.spentAt.isSmallerThanValue(to))
            ..orderBy([(t) => OrderingTerm.desc(t.spentAt)]))
          .watch();

  Future<int> insertExpense(ExpensesTableCompanion expense) =>
      into(expensesTable).insert(expense);

  Future<bool> updateExpense(ExpensesTableCompanion expense) =>
      update(expensesTable).replace(expense);

  Future<void> softDeleteExpense(int id) =>
      (update(expensesTable)..where((t) => t.id.equals(id)))
          .write(ExpensesTableCompanion(
        deletedAt: Value(DateTime.now()),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ));

  /// Total spending in cents for a period
  Future<int> getTotalAmountCents(DateTime from, DateTime to) async {
    final expenses = await getExpensesInRange(from, to);
    return expenses.fold<int>(0, (sum, e) => sum + e.amountCents);
  }

  Future<List<ExpensesTableData>> getUnsyncedExpenses() =>
      (select(expensesTable)..where((t) => t.isSynced.equals(false))).get();

  Future<void> markExpensesSynced(List<int> ids) =>
      (update(expensesTable)..where((t) => t.id.isIn(ids)))
          .write(const ExpensesTableCompanion(isSynced: Value(true)));
}
