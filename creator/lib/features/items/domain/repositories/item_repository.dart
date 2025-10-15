import '../entities/catalog_item.dart';
import '../value_objects/item_draft.dart';

abstract class ItemRepository {
  Stream<List<CatalogItem>> watchAll();
  Future<List<CatalogItem>> getAll();
  Future<CatalogItem?> findById(String id);
  Future<CatalogItem> create(ItemDraft draft);
  Future<CatalogItem> update(String id, ItemDraft draft);
  Future<void> delete(String id);
  Future<CatalogItem> approve(String id);
}
