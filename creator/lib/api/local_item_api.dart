import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/errors/validation_exception.dart';
import '../features/items/application/item_service.dart';
import '../features/items/domain/entities/catalog_item.dart';
import '../features/items/domain/value_objects/item_draft.dart';

class LocalItemApi {
  LocalItemApi(
    this._itemService, {
    InternetAddress? address,
    this.port = 8080,
  }) : address = address ?? InternetAddress.loopbackIPv4;

  final ItemService _itemService;
  final InternetAddress address;
  final int port;

  HttpServer? _server;

  Future<void> start() async {
    if (_server != null) {
      return;
    }

    final server = await HttpServer.bind(address, port);
    _server = server;
    unawaited(server.forEach(_handleRequest));

    debugPrint('Local catalog API listening on http://${address.address}:$port');
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    _addCorsHeaders(request.response);

    if (request.method == 'OPTIONS') {
      request.response
        ..statusCode = HttpStatus.noContent
        ..close();
      return;
    }

    try {
      final segments = request.uri.pathSegments.where((segment) => segment.isNotEmpty).toList();

      if (segments.isEmpty) {
        await _respondJson(request.response, const {'status': 'ok'});
        return;
      }

      if (segments.first != 'items') {
        await _respondNotFound(request);
        return;
      }

      if (segments.length == 1) {
        await _handleCollection(request);
        return;
      }

      if (segments.length == 2) {
        final id = segments[1];
        await _handleSingle(request, id);
        return;
      }

      if (segments.length == 3 && segments[2] == 'approve') {
        final id = segments[1];
        await _handleApproval(request, id);
        return;
      }

      await _respondNotFound(request);
    } catch (error, stackTrace) {
      debugPrint('API error: $error\n$stackTrace');
      await _respondJson(
        request.response,
        {'error': 'Internal server error'},
        statusCode: HttpStatus.internalServerError,
      );
    }
  }

  Future<void> _handleCollection(HttpRequest request) async {
    switch (request.method) {
      case 'GET':
        await _handleList(request);
        break;
      case 'POST':
        await _handleCreate(request);
        break;
      default:
        await _respondMethodNotAllowed(request);
        break;
    }
  }

  Future<void> _handleSingle(HttpRequest request, String id) async {
    switch (request.method) {
      case 'GET':
        final item = await _itemService.findById(id);
        if (item == null) {
          await _respondNotFound(request);
          return;
        }
        await _respondJson(request.response, item.toJson());
        break;
      case 'PUT':
        await _handleUpdate(request, id);
        break;
      case 'DELETE':
        await _itemService.delete(id);
        request.response
          ..statusCode = HttpStatus.noContent
          ..close();
        break;
      default:
        await _respondMethodNotAllowed(request);
        break;
    }
  }

  Future<void> _handleApproval(HttpRequest request, String id) async {
    if (request.method != 'POST') {
      await _respondMethodNotAllowed(request);
      return;
    }
    try {
      final approved = await _itemService.approve(id);
      await _respondJson(request.response, approved.toJson());
    } on ValidationException catch (error) {
      await _respondJson(
        request.response,
        {'errors': error.messages},
        statusCode: HttpStatus.badRequest,
      );
    } catch (error) {
      await _respondJson(
        request.response,
        {'error': error.toString()},
        statusCode: HttpStatus.badRequest,
      );
    }
  }

  Future<void> _handleList(HttpRequest request) async {
    final search = request.uri.queryParameters['search'] ?? '';
    final category = request.uri.queryParameters['category'] ?? '';
    final items = await _itemService.getAll();
    final filtered = _applyFilters(items, search: search, category: category);

    await _respondJson(
      request.response,
      filtered.map((item) => item.toJson()).toList(),
    );
  }

  Future<void> _handleCreate(HttpRequest request) async {
    final payload = await utf8.decoder.bind(request).join();
    if (payload.isEmpty) {
      await _respondJson(
        request.response,
        {'error': 'Missing body'},
        statusCode: HttpStatus.badRequest,
      );
      return;
    }

    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    final draft = ItemDraft.fromJson(decoded);
    try {
      final created = await _itemService.create(draft);
      await _respondJson(
        request.response,
        created.toJson(),
        statusCode: HttpStatus.created,
      );
    } on ValidationException catch (error) {
      await _respondJson(
        request.response,
        {'errors': error.messages},
        statusCode: HttpStatus.badRequest,
      );
    }
  }

  Future<void> _handleUpdate(HttpRequest request, String id) async {
    final payload = await utf8.decoder.bind(request).join();
    if (payload.isEmpty) {
      await _respondJson(
        request.response,
        {'error': 'Missing body'},
        statusCode: HttpStatus.badRequest,
      );
      return;
    }

    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    final draft = ItemDraft.fromJson(decoded);
    try {
      final updated = await _itemService.update(id, draft);
      await _respondJson(request.response, updated.toJson());
    } on ValidationException catch (error) {
      await _respondJson(
        request.response,
        {'errors': error.messages},
        statusCode: HttpStatus.badRequest,
      );
    }
  }

  List<CatalogItem> _applyFilters(
    List<CatalogItem> items, {
    required String search,
    required String category,
  }) {
    final query = search.trim().toLowerCase();
    final categoryTrimmed = category.trim();

    final filtered = items.where((item) {
      final matchesSearch = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.tags.any((tag) => tag.toLowerCase().contains(query));
      final matchesCategory = categoryTrimmed.isEmpty || item.category == categoryTrimmed;
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

  void _addCorsHeaders(HttpResponse response) {
    response.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS')
      ..set('Access-Control-Allow-Headers', 'Origin,Content-Type,Accept');
  }

  Future<void> _respondJson(
    HttpResponse response,
    Object body, {
    int statusCode = HttpStatus.ok,
  }) async {
    response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    await response.close();
  }

  Future<void> _respondNotFound(HttpRequest request) async {
    await _respondJson(
      request.response,
      {'error': 'Not found'},
      statusCode: HttpStatus.notFound,
    );
  }

  Future<void> _respondMethodNotAllowed(HttpRequest request) async {
    await _respondJson(
      request.response,
      {'error': 'Method not allowed'},
      statusCode: HttpStatus.methodNotAllowed,
    );
  }
}
