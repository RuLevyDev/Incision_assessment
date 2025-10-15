import 'dart:convert';

import '../value_objects/item_draft.dart';
import '../value_objects/quality_score.dart';

class CatalogItem {
  CatalogItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.tags,
    required this.score,
    this.isApproved = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory CatalogItem.fromDraft({
    required String id,
    required ItemDraft draft,
    bool isApproved = false,
  }) {
    final computed = QualityScoreCalculator.calculate(draft);
    return CatalogItem(
      id: id,
      title: draft.title,
      description: draft.description,
      category: draft.category,
      tags: List.unmodifiable(draft.tags),
      score: computed.value,
      isApproved: isApproved && computed.value >= QualityBand.minimumApprovalScore,
    );
  }

  final String id;
  final String title;
  final String description;
  final String category;
  final List<String> tags;
  final int score;
  final bool isApproved;
  final DateTime createdAt;
  final DateTime updatedAt;

  CatalogItem copyWith({
    String? title,
    String? description,
    String? category,
    List<String>? tags,
    int? score,
    bool? isApproved,
    DateTime? updatedAt,
  }) {
    return CatalogItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      score: score ?? this.score,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'tags': tags,
      'score': score,
      'isApproved': isApproved,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'qualityBand': QualityScoreCalculator.bandFor(score).name,
    };
  }

  static CatalogItem fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String? ?? '',
      tags: List<String>.from(json['tags'] as List? ?? const []),
      score: json['score'] as int? ?? 0,
      isApproved: json['isApproved'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}
