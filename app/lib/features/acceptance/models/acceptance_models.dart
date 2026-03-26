class AcceptanceChecklist {
  final String milestoneId;
  final String milestoneTitle;
  final double amount;
  final String payeeName;
  final String? previewUrl;
  final List<AcceptanceItem> items;

  const AcceptanceChecklist({
    required this.milestoneId,
    required this.milestoneTitle,
    required this.amount,
    required this.payeeName,
    this.previewUrl,
    required this.items,
  });

  int get totalCount => items.length;
  int get checkedCount => items.where((i) => i.isChecked).length;
  bool get allChecked => items.isNotEmpty && checkedCount == totalCount;
  double get progress => totalCount == 0 ? 0 : checkedCount / totalCount;

  AcceptanceChecklist copyWith({List<AcceptanceItem>? items}) {
    return AcceptanceChecklist(
      milestoneId: milestoneId,
      milestoneTitle: milestoneTitle,
      amount: amount,
      payeeName: payeeName,
      previewUrl: previewUrl,
      items: items ?? this.items,
    );
  }

  factory AcceptanceChecklist.fromJson(Map<String, dynamic> json) {
    return AcceptanceChecklist(
      milestoneId: json['milestone_id'] as String,
      milestoneTitle: json['milestone_title'] as String,
      amount: (json['amount'] as num).toDouble(),
      payeeName: json['payee_name'] as String,
      previewUrl: json['preview_url'] as String?,
      items: (json['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => AcceptanceItem.fromJson(e))
          .toList(),
    );
  }
}

class AcceptanceItem {
  final String id;
  final String description;
  final bool isChecked;
  final String? sourceCard;

  const AcceptanceItem({
    required this.id,
    required this.description,
    required this.isChecked,
    this.sourceCard,
  });

  AcceptanceItem copyWith({bool? isChecked}) {
    return AcceptanceItem(
      id: id,
      description: description,
      isChecked: isChecked ?? this.isChecked,
      sourceCard: sourceCard,
    );
  }

  factory AcceptanceItem.fromJson(Map<String, dynamic> json) {
    return AcceptanceItem(
      id: json['id'] as String,
      description: json['description'] as String,
      isChecked: json['is_checked'] as bool,
      sourceCard: json['source_card'] as String?,
    );
  }
}
