import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:creator/core/errors/validation_exception.dart';
import '../../application/item_service.dart';
import '../../domain/entities/catalog_item.dart';

class ItemListViewModel extends ChangeNotifier {
  ItemListViewModel(this._service) {
    _subscription = _service.watchAll().listen((items) {
      _items = items;
      notifyListeners();
    });
  }

  final ItemService _service;
  late final StreamSubscription<List<CatalogItem>> _subscription;

  List<CatalogItem> _items = <CatalogItem>[];
  String _searchTerm = '';
  String _categoryFilter = '';
  String? _errorMessage;
  String? _selectedId;

  List<CatalogItem> get items {
    final filtered = _items.where((item) {
      final query = _searchTerm.toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.tags.any((tag) => tag.toLowerCase().contains(query));
      final matchesCategory =
          _categoryFilter.isEmpty || item.category == _categoryFilter;
      return matchesSearch && matchesCategory;
    }).toList();

    filtered.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return filtered;
  }

  List<String> get categories {
    final unique = _items
        .map((item) => item.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    unique.sort();
    return unique;
  }

  String? get errorMessage => _errorMessage;
  String get categoryFilter => _categoryFilter;
  String get searchTerm => _searchTerm;

  CatalogItem? get selectedItem {
    if (_items.isEmpty) {
      return null;
    }
    if (_selectedId == null) {
      return _items.first;
    }
    try {
      return _items.firstWhere((item) => item.id == _selectedId);
    } on StateError {
      return _items.first;
    }
  }

  void setSearchTerm(String value) {
    _searchTerm = value.trim();
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _categoryFilter = category?.trim() ?? '';
    notifyListeners();
  }

  void selectItem(String? id) {
    _selectedId = id;
    notifyListeners();
  }

  Future<void> approve(String id) async {
    try {
      _errorMessage = null;
      await _service.approve(id);
    } on ValidationException catch (error) {
      _errorMessage = error.messages.values.join(' ');
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> remove(String id) async {
    await _service.delete(id);
    if (_selectedId == id) {
      _selectedId = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
