import 'package:hive/hive.dart';

part 'trend_analysis.g.dart';

@HiveType(typeId: 17)
enum TrendDirection {
  @HiveField(0)
  increasing,
  @HiveField(1)
  decreasing,
  @HiveField(2)
  stable,
}

@HiveType(typeId: 18)
class TrendAnalysis extends HiveObject {
  @HiveField(0)
  final String period;

  @HiveField(1)
  final DateTime startDate;

  @HiveField(2)
  final DateTime endDate;

  @HiveField(3)
  final double totalSpending;

  @HiveField(4)
  final Map<String, double> categoryBreakdown;

  @HiveField(5)
  final TrendDirection trendDirection;

  @HiveField(6)
  final double percentageChange;

  @HiveField(7)
  final DateTime createdAt;

  TrendAnalysis({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.totalSpending,
    required this.categoryBreakdown,
    required this.trendDirection,
    required this.percentageChange,
    required this.createdAt,
  });

  bool get isIncreasing => trendDirection == TrendDirection.increasing;
  bool get isDecreasing => trendDirection == TrendDirection.decreasing;
  bool get isStable => trendDirection == TrendDirection.stable;

  String get trendDescription {
    switch (trendDirection) {
      case TrendDirection.increasing:
        return 'Spending increased by ${percentageChange.toStringAsFixed(1)}%';
      case TrendDirection.decreasing:
        return 'Spending decreased by ${percentageChange.abs().toStringAsFixed(1)}%';
      case TrendDirection.stable:
        return 'Spending remained stable (${percentageChange.toStringAsFixed(1)}% change)';
    }
  }

  List<MapEntry<String, double>> get sortedCategories {
    final entries = categoryBreakdown.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  String get topCategory {
    if (categoryBreakdown.isEmpty) return 'No data';
    return sortedCategories.first.key;
  }

  double get topCategoryAmount {
    if (categoryBreakdown.isEmpty) return 0;
    return sortedCategories.first.value;
  }

  double get topCategoryPercentage {
    if (totalSpending == 0) return 0;
    return (topCategoryAmount / totalSpending) * 100;
  }

  TrendAnalysis copyWith({
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    double? totalSpending,
    Map<String, double>? categoryBreakdown,
    TrendDirection? trendDirection,
    double? percentageChange,
    DateTime? createdAt,
  }) {
    return TrendAnalysis(
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalSpending: totalSpending ?? this.totalSpending,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      trendDirection: trendDirection ?? this.trendDirection,
      percentageChange: percentageChange ?? this.percentageChange,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrendAnalysis &&
        other.period == period &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.totalSpending == totalSpending &&
        other.categoryBreakdown == categoryBreakdown &&
        other.trendDirection == trendDirection &&
        other.percentageChange == percentageChange &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      period,
      startDate,
      endDate,
      totalSpending,
      categoryBreakdown,
      trendDirection,
      percentageChange,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'TrendAnalysis(period: $period, startDate: $startDate, endDate: $endDate, totalSpending: $totalSpending, categoryBreakdown: $categoryBreakdown, trendDirection: $trendDirection, percentageChange: $percentageChange, createdAt: $createdAt)';
  }
}
