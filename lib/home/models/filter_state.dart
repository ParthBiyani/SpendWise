class FilterState {
  const FilterState({
    this.dateFilter = 'All Time',
    this.customStartDate,
    this.customEndDate,
    this.categories = const [],
    this.paymentMethods = const [],
    this.transactionType,
  });

  final String dateFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final List<String> categories;
  final List<String> paymentMethods;
  final List<String>? transactionType; // ['Money In'], ['Money Out'], both, or null

  bool get hasActiveFilters =>
      dateFilter != 'All Time' ||
      categories.isNotEmpty ||
      paymentMethods.isNotEmpty ||
      (transactionType != null && transactionType!.isNotEmpty && transactionType!.length != 2);

  int get activeFilterCount {
    int count = 0;
    if (dateFilter != 'All Time') count++;
    if (categories.isNotEmpty) count++;
    if (paymentMethods.isNotEmpty) count++;
    if (transactionType != null && transactionType!.isNotEmpty && transactionType!.length != 2) count++;
    return count;
  }

  FilterState copyWith({
    String? dateFilter,
    DateTime? Function()? customStartDate,
    DateTime? Function()? customEndDate,
    List<String>? categories,
    List<String>? paymentMethods,
    List<String>? Function()? transactionType,
  }) {
    return FilterState(
      dateFilter: dateFilter ?? this.dateFilter,
      customStartDate:
          customStartDate != null ? customStartDate() : this.customStartDate,
      customEndDate: customEndDate != null ? customEndDate() : this.customEndDate,
      categories: categories ?? this.categories,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      transactionType:
          transactionType != null ? transactionType() : this.transactionType,
    );
  }

  void clear() {}

  FilterState cleared() {
    return const FilterState();
  }
}
