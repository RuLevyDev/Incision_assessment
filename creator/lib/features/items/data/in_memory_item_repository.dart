import 'dart:async';

import 'package:creator/core/utils/id_generator.dart';
import '../domain/entities/catalog_item.dart';
import '../domain/repositories/item_repository.dart';
import '../domain/value_objects/item_draft.dart';
import '../domain/value_objects/quality_score.dart';

class InMemoryItemRepository implements ItemRepository {
  InMemoryItemRepository({IdGenerator? idGenerator})
      : _idGenerator = idGenerator ?? SequentialIdGenerator();

  final IdGenerator _idGenerator;
  final List<CatalogItem> _items = <CatalogItem>[];
  final StreamController<List<CatalogItem>> _controller =
      StreamController<List<CatalogItem>>.broadcast();

  @override
  Stream<List<CatalogItem>> watchAll() {
    _emit();
    return _controller.stream;
  }

  @override
  Future<List<CatalogItem>> getAll() async {
    return List.unmodifiable(_items);
  }

  @override
  Future<CatalogItem?> findById(String id) async {
    try {
      return _items.firstWhere((item) => item.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<CatalogItem> create(ItemDraft draft) async {
    final id = _idGenerator.nextId();
    final computed = CatalogItem.fromDraft(id: id, draft: draft);
    _items.add(computed);
    _emit();
    return computed;
  }

  @override
  Future<CatalogItem> update(String id, ItemDraft draft) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw StateError('Item not found for id $id');
    }

    final computed = CatalogItem.fromDraft(
      id: id,
      draft: draft,
      isApproved: _items[index].isApproved,
    );

    final shouldRevokeApproval = computed.score < QualityBand.minimumApprovalScore;
    final updated = computed.copyWith(
      isApproved: shouldRevokeApproval ? false : _items[index].isApproved,
    );

    _items[index] = updated;
    _emit();
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
    _emit();
  }

  @override
  Future<CatalogItem> approve(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw StateError('Item not found for id $id');
    }

    final existing = _items[index];
    if (existing.score < QualityBand.minimumApprovalScore) {
      throw StateError('Item does not meet approval threshold.');
    }

    final updated = existing.copyWith(isApproved: true);
    _items[index] = updated;
    _emit();
    return updated;
  }

  void _emit() {
    _controller.add(List.unmodifiable(_items));
  }
}
