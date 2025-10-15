import 'package:creator/core/errors/validation_exception.dart';
import '../domain/entities/catalog_item.dart';
import '../domain/repositories/item_repository.dart';
import '../domain/services/item_validator.dart';
import '../domain/value_objects/item_draft.dart';
import '../domain/value_objects/quality_score.dart';

class ItemService {
  ItemService(this._repository);

  final ItemRepository _repository;

  Stream<List<CatalogItem>> watchAll() => _repository.watchAll();

  Future<List<CatalogItem>> getAll() => _repository.getAll();

  Future<CatalogItem?> findById(String id) => _repository.findById(id);

  Future<CatalogItem> create(ItemDraft draft) async {
    _validate(draft);
    return _repository.create(draft);
  }

  Future<CatalogItem> update(String id, ItemDraft draft) async {
    _validate(draft);
    return _repository.update(id, draft);
  }

  Future<void> delete(String id) => _repository.delete(id);

  Future<CatalogItem> approve(String id) async {
    final item = await _repository.findById(id);
    if (item == null) {
      throw ValidationException({'id': 'Item not found.'});
    }
    if (item.score < QualityBand.minimumApprovalScore) {
      throw ValidationException({
        'approval':
            'Item must score at least ${QualityBand.minimumApprovalScore}.',
      });
    }
    return _repository.approve(id);
  }

  QualityScore previewScore(ItemDraft draft) {
    return QualityScoreCalculator.calculate(draft);
  }

  void _validate(ItemDraft draft) {
    ItemValidator.validate(draft);
  }
}
