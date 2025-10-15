class ItemDraft {
  ItemDraft({
    this.title = '',
    this.description = '',
    this.category = '',
    List<String>? tags,
  }) : tags = List.of(tags ?? const []);

  factory ItemDraft.fromJson(Map<String, dynamic> json) {
    final rawTags = (json['tags'] as List?) ?? const [];
    final tags = rawTags
        .map((tag) => tag?.toString().trim() ?? '')
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();

    return ItemDraft(
      title: (json['title'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      category: (json['category'] as String? ?? '').trim(),
      tags: tags,
    );
  }

  final String title;
  final String description;
  final String category;
  final List<String> tags;

  ItemDraft copyWith({
    String? title,
    String? description,
    String? category,
    List<String>? tags,
  }) {
    return ItemDraft(
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
    );
  }

  bool get hasCategory => category.trim().isNotEmpty;
  bool get hasTags => tags.isNotEmpty;
}
