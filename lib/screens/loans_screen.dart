import 'package:flutter/material.dart';

import '../models/loan.dart';
import '../models/emi_payment.dart';
import '../services/database_service.dart';

class LoansScreen extends StatefulWidget {
  final DatabaseService databaseService;

  const LoansScreen({super.key, required this.databaseService});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  DatabaseService get databaseService => widget.databaseService;

  bool _showCompletedLoans = false;

  String formatMoney(double amount) => '₹${amount.toStringAsFixed(2)}';

  String formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  DateTime _nextMonthDate(DateTime date) {
    final monthIndex = date.month;
    final year = date.year + monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;

    return DateTime(year, month, day);
  }

  bool _isLoanCompleted(Loan loan) {
    final schedule = databaseService.getLoanEmiPayments(loan.id);

    return schedule.isNotEmpty && schedule.every((payment) => payment.isPaid);
  }

  Future<void> _confirmDeleteLoan(Loan loan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Loan?'),
        content: Text(
          'Delete "${loan.name}" and its unpaid EMI schedule? '
          'Loans with recorded payments cannot be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await databaseService.deleteLoan(loan.id);

      if (!mounted) return;
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loan deleted successfully')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot delete loan: '
            '${error.toString().replaceFirst('Bad state: ', '')}',
          ),
        ),
      );
    }
  }

  Future<void> _showAddLoanDialog() async {
    if (databaseService.accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add an account before adding a loan.'),
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final lenderController = TextEditingController();
    final principalController = TextEditingController();
    final downPaymentController = TextEditingController(text: '0');
    final rateController = TextEditingController(text: '0');
    final tenureController = TextEditingController();
    final noteController = TextEditingController();

    DateTime startDate = DateTime.now();
    DateTime firstEmiDate = _nextMonthDate(startDate);
    int emiDay = firstEmiDate.day.clamp(1, 28);
    String? accountId = databaseService.accounts.first.id;
    bool isSaving = false;

    try {
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogBuildContext, setDialogState) {
              Future<void> pickStartDate() async {
                final picked = await showDatePicker(
                  context: dialogBuildContext,
                  initialDate: startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );

                if (picked == null || !dialogBuildContext.mounted) return;

                setDialogState(() {
                  startDate = picked;
                  if (firstEmiDate.isBefore(startDate)) {
                    firstEmiDate = _nextMonthDate(startDate);
                    emiDay = firstEmiDate.day.clamp(1, 28);
                  }
                });
              }

              Future<void> pickFirstEmiDate() async {
                final picked = await showDatePicker(
                  context: dialogBuildContext,
                  initialDate: firstEmiDate.isBefore(startDate)
                      ? startDate
                      : firstEmiDate,
                  firstDate: startDate,
                  lastDate: DateTime(2100),
                );

                if (picked == null || !dialogBuildContext.mounted) return;

                setDialogState(() {
                  firstEmiDate = picked;
                  emiDay = picked.day.clamp(1, 28);
                });
              }

              return AlertDialog(
                title: const Text('Add Loan'),
                content: SizedBox(
                  width: 440,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Loan name',
                              hintText: 'e.g. Car Loan',
                              prefixIcon: Icon(Icons.account_balance),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Enter a loan name'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: lenderController,
                            decoration: const InputDecoration(
                              labelText: 'Bank or lender',
                              prefixIcon: Icon(Icons.business),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Enter the lender'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: principalController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Loan amount borrowed (₹)',
                              helperText:
                                  'Enter only the amount borrowed from the lender',
                              prefixIcon: Icon(Icons.currency_rupee),
                            ),
                            validator: (value) {
                              final amount = double.tryParse(
                                value?.trim() ?? '',
                              );
                              if (amount == null ||
                                  !amount.isFinite ||
                                  amount <= 0) {
                                return 'Enter a valid loan amount';
                              }
                              return null;
                            },
                            onChanged: (_) => setDialogState(() {}),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: downPaymentController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Down payment (₹)',
                              helperText: 'Enter 0 if no down payment was made',
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                            validator: (value) {
                              final amount = double.tryParse(
                                value?.trim() ?? '',
                              );
                              if (amount == null ||
                                  !amount.isFinite ||
                                  amount < 0) {
                                return 'Enter a valid down payment';
                              }
                              return null;
                            },
                            onChanged: (_) => setDialogState(() {}),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: rateController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Annual interest rate (%)',
                              prefixIcon: Icon(Icons.percent),
                            ),
                            validator: (value) {
                              final rate = double.tryParse(value?.trim() ?? '');
                              if (rate == null || !rate.isFinite || rate < 0) {
                                return 'Enter a valid interest rate';
                              }
                              return null;
                            },
                            onChanged: (_) => setDialogState(() {}),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: tenureController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Loan tenure (months)',
                              prefixIcon: Icon(Icons.calendar_month),
                            ),
                            validator: (value) {
                              final months = int.tryParse(value?.trim() ?? '');
                              if (months == null || months <= 0) {
                                return 'Enter months greater than zero';
                              }
                              return null;
                            },
                            onChanged: (_) => setDialogState(() {}),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: accountId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'EMI payment account',
                              prefixIcon: Icon(Icons.account_balance_wallet),
                            ),
                            items: databaseService.accounts
                                .map(
                                  (account) => DropdownMenuItem<String>(
                                    value: account.id,
                                    child: Text(
                                      '${account.name} (${account.bankName})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: isSaving
                                ? null
                                : (value) {
                                    setDialogState(() => accountId = value);
                                  },
                            validator: (value) =>
                                value == null ? 'Select an account' : null,
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Loan start date'),
                            subtitle: Text(formatDate(startDate)),
                            trailing: const Icon(Icons.calendar_month),
                            onTap: isSaving ? null : pickStartDate,
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('First EMI due date'),
                            subtitle: Text(formatDate(firstEmiDate)),
                            trailing: const Icon(Icons.event),
                            onTap: isSaving ? null : pickFirstEmiDate,
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            initialValue: emiDay,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Recurring EMI day',
                              helperText: 'Applies from the second EMI onwards',
                              prefixIcon: Icon(Icons.event_repeat),
                            ),
                            items: List.generate(
                              28,
                              (index) => DropdownMenuItem<int>(
                                value: index + 1,
                                child: Text('Day ${index + 1} of each month'),
                              ),
                            ),
                            onChanged: isSaving
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setDialogState(() => emiDay = value);
                                    }
                                  },
                            validator: (value) =>
                                value == null ? 'Select an EMI day' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: noteController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Notes (optional)',
                              prefixIcon: Icon(Icons.notes),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if ((double.tryParse(
                                        principalController.text.trim(),
                                      ) ??
                                      0) >
                                  0 &&
                              (int.tryParse(tenureController.text.trim()) ??
                                      0) >
                                  0)
                            _buildEstimate(
                              double.tryParse(
                                    principalController.text.trim(),
                                  ) ??
                                  0,
                              double.tryParse(rateController.text.trim()) ?? 0,
                              int.tryParse(tenureController.text.trim()) ?? 0,
                              double.tryParse(
                                    downPaymentController.text.trim(),
                                  ) ??
                                  0,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;

                            final selectedAccountId = accountId;
                            if (selectedAccountId == null) return;

                            final principal = double.tryParse(
                              principalController.text.trim(),
                            );
                            final downPayment = double.tryParse(
                              downPaymentController.text.trim(),
                            );
                            final rate = double.tryParse(
                              rateController.text.trim(),
                            );
                            final tenure = int.tryParse(
                              tenureController.text.trim(),
                            );

                            if (principal == null ||
                                !principal.isFinite ||
                                principal <= 0 ||
                                downPayment == null ||
                                !downPayment.isFinite ||
                                downPayment < 0 ||
                                rate == null ||
                                !rate.isFinite ||
                                rate < 0 ||
                                tenure == null ||
                                tenure <= 0) {
                              return;
                            }

                            final loan = Loan(
                              id: DateTime.now().microsecondsSinceEpoch
                                  .toString(),
                              name: nameController.text.trim(),
                              lender: lenderController.text.trim(),
                              principal: principal,
                              downPayment: downPayment,
                              annualInterestRate: rate,
                              tenureMonths: tenure,
                              startDate: startDate,
                              firstEmiDate: firstEmiDate,
                              emiDay: emiDay,
                              accountId: selectedAccountId,
                              note: noteController.text.trim(),
                            );

                            setDialogState(() => isSaving = true);
                            var loanSaved = false;

                            try {
                              await databaseService.addLoan(loan);
                              loanSaved = true;
                              await databaseService.createEmiSchedule(loan);

                              if (!dialogContext.mounted) return;
                              Navigator.pop(dialogContext, true);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Loan and EMI schedule saved',
                                    ),
                                  ),
                                );
                              }
                            } catch (error) {
                              if (loanSaved) {
                                try {
                                  await databaseService.deleteLoan(loan.id);
                                } catch (_) {
                                  // Preserve the original error.
                                }
                              }

                              if (!dialogBuildContext.mounted) return;
                              setDialogState(() => isSaving = false);

                              ScaffoldMessenger.of(
                                dialogBuildContext,
                              ).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to save loan: $error'),
                                ),
                              );
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Loan'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (saved == true && mounted) setState(() {});
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      nameController.dispose();
      lenderController.dispose();
      principalController.dispose();
      downPaymentController.dispose();
      rateController.dispose();
      tenureController.dispose();
      noteController.dispose();
    }
  }

  Widget _buildEstimate(
    double principal,
    double rate,
    int tenure,
    double downPayment,
  ) {
    if (!principal.isFinite ||
        principal <= 0 ||
        !rate.isFinite ||
        rate < 0 ||
        tenure <= 0 ||
        !downPayment.isFinite ||
        downPayment < 0) {
      return const SizedBox.shrink();
    }

    final monthlyRate = rate / 1200;
    final emi = monthlyRate == 0
        ? principal / tenure
        : principal *
              monthlyRate *
              _power(1 + monthlyRate, tenure) /
              (_power(1 + monthlyRate, tenure) - 1);

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estimated loan summary',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _estimateRow('Down payment', formatMoney(downPayment)),
            _estimateRow('Borrowed amount', formatMoney(principal)),
            _estimateRow('Monthly EMI', formatMoney(emi)),
            _estimateRow(
              'Total interest',
              formatMoney(emi * tenure - principal),
            ),
          ],
        ),
      ),
    );
  }

  double _power(double base, int exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  Widget _estimateRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _showSchedule(Loan loan) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, refreshSheet) {
            final payments = databaseService.getLoanEmiPayments(loan.id);

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.78,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loan.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text('Lender: ${loan.lender}'),
                          Text(
                            'Borrowed amount: ${formatMoney(loan.principal)}',
                          ),
                          Text(
                            'Down payment: ${formatMoney(loan.downPayment)}',
                          ),
                          Text(
                            'Total purchase cost: '
                            '${formatMoney(loan.totalPurchaseCost)}',
                          ),
                          Text('Monthly EMI: ${formatMoney(loan.monthlyEmi)}'),
                          Text(
                            'Estimated interest: '
                            '${formatMoney(loan.totalInterest)}',
                          ),
                          Text('First EMI: ${formatDate(loan.firstEmiDate)}'),
                          Text('Recurring EMI day: ${loan.emiDay}'),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: payments.isEmpty
                          ? const Center(child: Text('No EMI schedule found'))
                          : ListView.separated(
                              itemCount: payments.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final payment = payments[index];

                                return _emiTile(
                                  payment,
                                  onPay: payment.isPaid
                                      ? null
                                      : () async {
                                          final success =
                                              await _showPayEmiDialog(payment);

                                          if (success && mounted) {
                                            refreshSheet(() {});
                                            setState(() {});
                                          }
                                        },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _showPayEmiDialog(EmiPayment payment) async {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(
      text: payment.remainingAmount.toStringAsFixed(2),
    );

    DateTime paymentDate = DateTime.now();
    bool isSaving = false;

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogBuildContext, setDialogState) {
              return AlertDialog(
                title: Text('Pay EMI ${payment.installmentNumber}'),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Remaining: ${formatMoney(payment.remainingAmount)}',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: amountController,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Payment amount (₹)',
                          ),
                          validator: (value) {
                            final amount = double.tryParse(value?.trim() ?? '');
                            if (amount == null ||
                                !amount.isFinite ||
                                amount <= 0) {
                              return 'Enter a valid payment amount';
                            }
                            if (amount > payment.remainingAmount + 0.005) {
                              return 'Cannot exceed remaining EMI';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Payment date'),
                          subtitle: Text(formatDate(paymentDate)),
                          trailing: const Icon(Icons.calendar_month),
                          onTap: isSaving
                              ? null
                              : () async {
                                  final picked = await showDatePicker(
                                    context: dialogBuildContext,
                                    initialDate: paymentDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );

                                  if (picked != null &&
                                      dialogBuildContext.mounted) {
                                    setDialogState(() => paymentDate = picked);
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;

                            final amount = double.tryParse(
                              amountController.text.trim(),
                            );
                            if (amount == null || !amount.isFinite) return;

                            setDialogState(() => isSaving = true);

                            try {
                              await databaseService.recordEmiPayment(
                                emiPaymentId: payment.id,
                                amount: amount,
                                paymentDate: paymentDate,
                              );

                              if (!dialogContext.mounted) return;
                              Navigator.pop(dialogContext, true);
                            } catch (error) {
                              if (!dialogBuildContext.mounted) return;
                              setDialogState(() => isSaving = false);

                              ScaffoldMessenger.of(
                                dialogBuildContext,
                              ).showSnackBar(
                                SnackBar(
                                  content: Text('Payment failed: $error'),
                                ),
                              );
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Record Payment'),
                  ),
                ],
              );
            },
          );
        },
      );

      return result == true;
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      amountController.dispose();
    }
  }

  Widget _emiTile(EmiPayment payment, {VoidCallback? onPay}) {
    final status = payment.isPaid
        ? 'Paid'
        : payment.isOverdue
        ? 'Overdue'
        : payment.paidAmount > 0
        ? 'Part-paid'
        : 'Pending';

    final color = payment.isPaid
        ? Colors.green
        : payment.isOverdue
        ? Colors.red
        : Theme.of(context).colorScheme.primary;

    return ListTile(
      leading: CircleAvatar(child: Text('${payment.installmentNumber}')),
      title: Text('EMI ${payment.installmentNumber}'),
      subtitle: Text(
        'Due ${formatDate(payment.dueDate)}\n'
        'Principal ${formatMoney(payment.principalComponent)} · '
        'Interest ${formatMoney(payment.interestComponent)}\n'
        'Paid ${formatMoney(payment.paidAmount)} · '
        'Remaining ${formatMoney(payment.remainingAmount)}',
      ),
      isThreeLine: true,
      trailing: onPay == null
          ? Text(
              status,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  status,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 30,
                  child: FilledButton(
                    onPressed: onPay,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Pay'),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loans = databaseService.loans;
    final pendingLoans = loans
        .where((loan) => !_isLoanCompleted(loan))
        .toList();
    final completedLoans = loans.where(_isLoanCompleted).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Loans & EMIs')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLoanDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Loan'),
      ),
      body: loans.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No loans added yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add a loan to calculate its EMI and generate a payment schedule.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _showAddLoanDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Your First Loan'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _summaryCard(loans),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Pending Loans',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      '${pendingLoans.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (pendingLoans.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green),
                          SizedBox(width: 12),
                          Expanded(child: Text('No pending loans. Great job!')),
                        ],
                      ),
                    ),
                  )
                else
                  ...pendingLoans.map(_loanCard),
                if (completedLoans.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.check_circle_outline),
                          ),
                          title: const Text('Completed Loans'),
                          subtitle: Text(
                            '${completedLoans.length} '
                            '${completedLoans.length == 1 ? 'loan' : 'loans'} completed',
                          ),
                          trailing: Icon(
                            _showCompletedLoans
                                ? Icons.expand_less
                                : Icons.expand_more,
                          ),
                          onTap: () {
                            setState(() {
                              _showCompletedLoans = !_showCompletedLoans;
                            });
                          },
                        ),
                        if (_showCompletedLoans) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                            child: Column(
                              children: completedLoans.map(_loanCard).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _summaryCard(List<Loan> loans) {
    final totalPrincipal = loans.fold(0.0, (sum, loan) => sum + loan.principal);
    final totalDownPayment = loans.fold(
      0.0,
      (sum, loan) => sum + loan.downPayment,
    );
    final monthlyEmis = loans.fold(0.0, (sum, loan) => sum + loan.monthlyEmi);

    final allPayments = databaseService.emiPayments.where(
      (payment) => loans.any((loan) => loan.id == payment.loanId),
    );

    final pendingCount = allPayments.where((payment) => !payment.isPaid).length;
    final totalEmiPending = allPayments.fold(
      0.0,
      (sum, payment) => sum + payment.remainingAmount,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loan overview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _summaryValue(
                    'Total borrowed',
                    formatMoney(totalPrincipal),
                  ),
                ),
                Expanded(
                  child: _summaryValue(
                    'Monthly EMIs',
                    formatMoney(monthlyEmis),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _summaryValue(
                    'Total down payment',
                    formatMoney(totalDownPayment),
                  ),
                ),
                Expanded(
                  child: _summaryValue(
                    'EMI pending',
                    formatMoney(totalEmiPending),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _summaryValue('Unpaid installments', '$pendingCount'),
                ),
                Expanded(child: _summaryValue('Loans', '${loans.length}')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 5),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _loanCard(Loan loan) {
    final schedule = databaseService.getLoanEmiPayments(loan.id);
    final paidCount = schedule.where((payment) => payment.isPaid).length;
    final pendingCount = schedule.where((payment) => !payment.isPaid).length;
    final progress = schedule.isEmpty ? 0.0 : paidCount / schedule.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showSchedule(loan),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.account_balance)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          loan.lender,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Loan options',
                    onSelected: (value) {
                      if (value == 'delete') _confirmDeleteLoan(loan);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete loan'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _summaryValue(
                      'Borrowed',
                      formatMoney(loan.principal),
                    ),
                  ),
                  Expanded(
                    child: _summaryValue(
                      'Down payment',
                      formatMoney(loan.downPayment),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _summaryValue(
                      'Monthly EMI',
                      formatMoney(loan.monthlyEmi),
                    ),
                  ),
                  Expanded(
                    child: _summaryValue(
                      'Interest',
                      formatMoney(loan.totalInterest),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${loan.annualInterestRate}% annual interest · '
                '${loan.tenureMonths} months',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'First EMI: ${formatDate(loan.firstEmiDate)} · '
                'Recurring day: ${loan.emiDay}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$paidCount paid · $pendingCount pending',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    'View schedule',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
