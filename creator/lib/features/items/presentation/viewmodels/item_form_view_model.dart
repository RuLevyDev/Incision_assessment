import 'package:flutter/foundation.dart';

import 'package:creator/core/errors/validation_exception.dart';
import '../../application/item_service.dart';
import '../../domain/entities/catalog_item.dart';
import '../../domain/value_objects/item_draft.dart';
import '../../domain/value_objects/quality_score.dart';

class ItemFormViewModel extends ChangeNotifier {
  ItemFormViewModel(this._service);

  final ItemService _service;

  ItemDraft _draft = ItemDraft();
  String? _editingId;
  Map<String, String> _errors = <String, String>{};
  bool _isSaving = false;

  ItemDraft get draft => _draft;
  Map<String, String> get errors => _errors;
  bool get isSaving => _isSaving;
  bool get isEditing => _editingId != null;

  QualityScore get score => _service.previewScore(_draft);

  void updateTitle(String value) {
    _draft = _draft.copyWith(title: value);
    notifyListeners();
  }

  void updateDescription(String value) {
    _draft = _draft.copyWith(description: value);
    notifyListeners();
  }

  void updateCategory(String value) {
    _draft = _draft.copyWith(category: value);
    notifyListeners();
  }

  void addTag(String tag) {
    final normalized = tag.trim();
    if (normalized.isEmpty || _draft.tags.contains(normalized)) {
      return;
    }
    final updatedTags = List<String>.from(_draft.tags)..add(normalized);
    _draft = _draft.copyWith(tags: updatedTags);
    notifyListeners();
  }

  void removeTag(String tag) {
    final updatedTags = List<String>.from(_draft.tags)..remove(tag);
    _draft = _draft.copyWith(tags: updatedTags);
    notifyListeners();
  }

  void loadForEditing(CatalogItem? item) {
    if (item == null) {
      reset();
      return;
    }

    _editingId = item.id;
    _draft = ItemDraft(
      title: item.title,
      description: item.description,
      category: item.category,
      tags: item.tags,
    );
    _errors = <String, String>{};
    notifyListeners();
  }

  void reset() {
    _draft = ItemDraft();
    _editingId = null;
    _errors = <String, String>{};
    notifyListeners();
  }

  Future<CatalogItem?> submit() async {
    _isSaving = true;
    _errors = <String, String>{};
    notifyListeners();
    try {
      if (_editingId == null) {
        final created = await _service.create(_draft);
        reset();
        return created;
      } else {
        final updated = await _service.update(_editingId!, _draft);
        _editingId = updated.id;
        _draft = ItemDraft(
          title: updated.title,
          description: updated.description,
          category: updated.category,
          tags: updated.tags,
        );
        return updated;
      }
    } on ValidationException catch (error) {
      _errors = error.messages;
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
