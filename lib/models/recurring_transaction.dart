import 'package:hive/hive.dart';

part 'recurring_transaction.g.dart';

@HiveType(typeId: 2)
enum Frequency {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
  @HiveField(3)
  yearly,
}

@HiveType(typeId: 3)
class RecurringTransaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String categoryId;

  @HiveField(4)
  final bool isExpense;

  @HiveField(5)
  final Frequency frequency;

  @HiveField(6)
  DateTime nextRun;

  RecurringTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.isExpense,
    required this.frequency,
    required this.nextRun,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'categoryId': categoryId,
      'isExpense': isExpense,
      'frequency': frequency.index, // Store as index for simplicity
      'nextRun': nextRun.toIso8601String(),
    };
  }

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    return RecurringTransaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      categoryId: map['categoryId'],
      isExpense: map['isExpense'],
      frequency: Frequency.values[map['frequency']],
      nextRun: DateTime.parse(map['nextRun']),
    );
  }
}
