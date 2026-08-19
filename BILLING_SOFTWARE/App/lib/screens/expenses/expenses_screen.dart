import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/app_notifier.dart';
import '../../core/localization.dart';
import '../../models/expense.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/theme_provider.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Utilities',
    'Rent',
    'Staff & Salary',
    'Transport',
    'Tea & Snacks',
    'Maintenance',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshExpenses();
    });
  }

  Future<void> _refreshExpenses() async {
    final auth = context.read<AuthProvider>();
    if (auth.apiService.baseUrl.isNotEmpty) {
      await context.read<ExpenseProvider>().fetchExpenses(auth.apiService);
    }
  }

  void _showExpenseDialog({Expense? expense}) {
    final isEdit = expense != null;
    final titleCtrl = TextEditingController(text: expense?.title ?? '');
    final amountCtrl = TextEditingController(text: expense != null ? expense.amount.toStringAsFixed(0) : '');
    final notesCtrl = TextEditingController(text: expense?.notes ?? '');
    String category = expense?.category ?? 'Utilities';
    String paymentMode = expense?.paymentMode ?? 'Cash';

    final categoryOptions = ['Utilities', 'Rent', 'Staff & Salary', 'Transport', 'Tea & Snacks', 'Maintenance', 'Other'];
    if (!categoryOptions.contains(category)) {
      category = 'Other';
    }

    final modeOptions = ['Cash', 'UPI', 'ECO Wallet', 'Bank Transfer'];
    if (!modeOptions.contains(paymentMode)) {
      paymentMode = 'Cash';
    }

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark || AppColors.isDark;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 14,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF37475A) : const Color(0xFFD5CEBF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isEdit ? Icons.edit_note_rounded : Icons.receipt_long_rounded,
                              size: 20,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            (isEdit ? ctx.tr('edit_expense') : ctx.tr('add_expense')).toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                        onPressed: isSaving ? null : () => Navigator.pop(ctx),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B2432) : const Color(0xFFF9F7F4),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2B3A4F) : const Color(0xFFE8E2D8),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'Expense Title / Description *',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        TextField(
                          controller: titleCtrl,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. Electricity Bill, Shop Rent, Tea & Snacks',
                            prefixIcon: Icon(Icons.description_outlined, color: AppColors.terracotta, size: 20),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'Amount (₹) *',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        TextField(
                          controller: amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.error,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppColors.error, size: 20),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 8,
                          children: [50, 100, 200, 500, 1000].map((preset) {
                            return ActionChip(
                              label: Text('+₹$preset'),
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFD5CEBF) : const Color(0xFF4A443A),
                              ),
                              backgroundColor: isDark ? const Color(0xFF243042) : const Color(0xFFEBE6DC),
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              onPressed: () {
                                final cur = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                                final next = cur + preset;
                                amountCtrl.text = next.truncateToDouble() == next ? next.toInt().toString() : next.toString();
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B2432) : const Color(0xFFF9F7F4),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2B3A4F) : const Color(0xFFE8E2D8),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Category',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categoryOptions.map((c) {
                            final isSel = category == c;
                            return ChoiceChip(
                              label: Text(ctx.trExpenseCategory(c)),
                              selected: isSel,
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                color: isSel ? Colors.white : AppColors.textPrimary,
                              ),
                              selectedColor: AppColors.terracotta,
                              backgroundColor: isDark ? const Color(0xFF243042) : const Color(0xFFEBE6DC),
                              showCheckmark: false,
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              onSelected: (sel) {
                                if (sel) setModalState(() => category = c);
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Payment Mode',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: modeOptions.map((m) {
                            final isSel = paymentMode == m;
                            return ChoiceChip(
                              label: Text(
                                m == 'Cash'
                                    ? ctx.tr('cash')
                                    : (m == 'UPI'
                                        ? ctx.tr('upi')
                                        : (m == 'ECO Wallet' ? ctx.tr('eco_wallet') : ctx.tr('bank_transfer'))),
                              ),
                              selected: isSel,
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                color: isSel ? Colors.white : AppColors.textPrimary,
                              ),
                              selectedColor: AppColors.forestMint,
                              backgroundColor: isDark ? const Color(0xFF243042) : const Color(0xFFEBE6DC),
                              showCheckmark: false,
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              onSelected: (sel) {
                                if (sel) setModalState(() => paymentMode = m);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B2432) : const Color(0xFFF9F7F4),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2B3A4F) : const Color(0xFFE8E2D8),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'Notes / Remarks (Optional)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        TextField(
                          controller: notesCtrl,
                          style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Any extra details or memo',
                            prefixIcon: Icon(Icons.notes_rounded, color: AppColors.textSecondary, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                              final title = titleCtrl.text.trim();
                              if (title.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(context.tr('enter_expense_title')),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              if (amt <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(context.tr('enter_valid_amount')),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);
                              final auth = context.read<AuthProvider>();
                              final expenseProvider = context.read<ExpenseProvider>();

                              if (isEdit) {
                                final updated = Expense(
                                  id: expense.id,
                                  title: title,
                                  amount: amt,
                                  category: category,
                                  paymentMode: paymentMode,
                                  notes: notesCtrl.text.trim(),
                                  date: expense.date,
                                );
                                final success = await expenseProvider.updateExpense(auth.apiService, updated);
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  if (success) {
                                    AppNotifier.success(context, 'Expense updated successfully', title: 'EXPENSE UPDATED');
                                  } else {
                                    AppNotifier.error(context, 'Failed to update expense', title: 'UPDATE ERROR');
                                  }
                                }
                              } else {
                                final newExp = Expense(
                                  id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
                                  title: title,
                                  amount: amt,
                                  category: category,
                                  paymentMode: paymentMode,
                                  notes: notesCtrl.text.trim(),
                                  date: DateTime.now(),
                                );
                                final success = await expenseProvider.addExpense(auth.apiService, newExp);
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  if (success) {
                                    AppNotifier.success(context, 'Expense added successfully', title: 'EXPENSE SAVED');
                                  } else {
                                    AppNotifier.error(context, 'Failed to add expense', title: 'EXPENSE ERROR');
                                  }
                                }
                              }
                            },
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text(
                        isSaving
                            ? 'SAVING EXPENSE...'
                            : (isEdit ? 'UPDATE EXPENSE' : 'SAVE EXPENSE RECORD'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteExpense(Expense expense) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.tr('delete_expense'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          '${context.tr('confirm_delete_expense')} "${expense.title}" (₹${expense.amount.toStringAsFixed(0)})',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(context.tr('cancel').toUpperCase(), style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final auth = context.read<AuthProvider>();
              final success = await context.read<ExpenseProvider>().removeExpense(auth.apiService, expense.id);
              if (mounted) {
                if (success) {
                  AppNotifier.success(context, 'Expense deleted successfully', title: 'EXPENSE DELETED');
                } else {
                  AppNotifier.error(context, 'Failed to delete expense', title: 'DELETE ERROR');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(context.tr('delete').toUpperCase()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final allExpenses = expenseProvider.expenses;
    final filteredExpenses = _selectedCategory == 'All'
        ? allExpenses
        : allExpenses.where((e) => e.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();

    final todayTotal = expenseProvider.todayExpenseTotal;
    final totalSum = expenseProvider.totalExpenses;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          context.tr('store_expenses').toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: AppColors.terracotta),
            onPressed: () => _showExpenseDialog(),
            tooltip: context.tr('expenses'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshExpenses,
        color: AppColors.terracotta,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${context.tr('today').toUpperCase()} ${context.tr('store_expenses').toUpperCase()}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${todayTotal.toStringAsFixed(0)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('total_expenses').toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${totalSum.toStringAsFixed(0)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(context.trExpenseCategory(cat)),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                        selectedColor: AppColors.primaryContainer,
                        backgroundColor: AppColors.surface,
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.terracotta : AppColors.textSecondary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: isSelected ? AppColors.terracotta : AppColors.borderSubtle),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: expenseProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredExpenses.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_rounded, size: 54, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                Text(
                                  context.tr('no_expenses_found'),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.tr('add_expense_hint'),
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                          itemCount: filteredExpenses.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final exp = filteredExpenses[index];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.receipt_long_rounded, color: AppColors.error, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exp.title,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${exp.category} • ${exp.paymentMode} • ${DateFormat('dd MMM yyyy').format(exp.date)}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        if (exp.notes.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            exp.notes,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                              color: AppColors.textMuted,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '-₹${exp.amount.toStringAsFixed(0)}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.error,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () => _showExpenseDialog(expense: exp),
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryContainer,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Icon(Icons.edit_rounded, size: 16, color: AppColors.terracotta),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          InkWell(
                                            onTap: () => _confirmDeleteExpense(exp),
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: AppColors.error.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
