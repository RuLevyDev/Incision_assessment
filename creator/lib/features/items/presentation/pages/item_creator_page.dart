import 'package:flutter/material.dart';

import '../../domain/entities/catalog_item.dart';
import '../../domain/value_objects/quality_score.dart';
import '../viewmodels/item_form_view_model.dart';
import '../viewmodels/item_list_view_model.dart';
import '../widgets/quality_badge.dart';

class ItemCreatorPage extends StatefulWidget {
  const ItemCreatorPage({
    required this.listViewModel,
    required this.formViewModel,
    super.key,
  });

  final ItemListViewModel listViewModel;
  final ItemFormViewModel formViewModel;

  @override
  State<ItemCreatorPage> createState() => _ItemCreatorPageState();
}

class _ItemCreatorPageState extends State<ItemCreatorPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.formViewModel.addListener(_onFormChanged);
    _onFormChanged();
  }

  @override
  void dispose() {
    widget.formViewModel.removeListener(_onFormChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    final draft = widget.formViewModel.draft;
    if (_titleController.text != draft.title) {
      _titleController.value = _titleController.value.copyWith(
        text: draft.title,
        selection: TextSelection.collapsed(offset: draft.title.length),
      );
    }
    if (_descriptionController.text != draft.description) {
      _descriptionController.value = _descriptionController.value.copyWith(
        text: draft.description,
        selection: TextSelection.collapsed(offset: draft.description.length),
      );
    }
    if (_categoryController.text != draft.category) {
      _categoryController.value = _categoryController.value.copyWith(
        text: draft.category,
        selection: TextSelection.collapsed(offset: draft.category.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final merged = Listenable.merge([widget.formViewModel, widget.listViewModel]);
    return AnimatedBuilder(
      animation: merged,
      builder: (context, _) {
        final form = widget.formViewModel;
        final list = widget.listViewModel;
        final items = list.items;
        final selected = list.selectedItem;
        final quality = form.score;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            return Scaffold(
              appBar: AppBar(
                title: const Text('Catalog Creator'),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildForm(context, form, quality)),
                          const SizedBox(width: 24),
                          Expanded(child: _buildList(context, list, items, selected)),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildForm(context, form, quality),
                            const SizedBox(height: 24),
                            _buildList(context, list, items, selected),
                          ],
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildForm(BuildContext context, ItemFormViewModel form, QualityScore quality) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      errorText: form.errors['title'],
                    ),
                    onChanged: form.updateTitle,
                  ),
                ),
                const SizedBox(width: 12),
                QualityBadge(score: quality.value, band: quality.band),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                errorText: form.errors['description'],
              ),
              maxLines: 4,
              onChanged: form.updateDescription,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: 'Category',
                errorText: form.errors['category'],
              ),
              onChanged: form.updateCategory,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      labelText: 'Add tag',
                      errorText: form.errors['tags'],
                    ),
                    onSubmitted: (value) {
                      form.addTag(value);
                      _tagController.clear();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    form.addTag(_tagController.text);
                    _tagController.clear();
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: form.draft.tags
                  .map(
                    (tag) => InputChip(
                      label: Text(tag),
                      onDeleted: () => form.removeTag(tag),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (form.isEditing)
                  TextButton(
                    onPressed: form.reset,
                    child: const Text('Cancel'),
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: form.isSaving
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final result = await form.submit();
                          if (result != null) {
                            widget.listViewModel.selectItem(result.id);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  form.isEditing ? 'Item updated.' : 'Item created.',
                                ),
                              ),
                            );
                          }
                        },
                  icon: form.isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(form.isEditing ? Icons.save : Icons.add),
                  label: Text(form.isEditing ? 'Save changes' : 'Create item'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    ItemListViewModel list,
    List<CatalogItem> items,
    CatalogItem? selected,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: list.setSearchTerm,
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: list.categoryFilter.isEmpty ? '' : list.categoryFilter,
                  hint: const Text('Filter category'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('All categories'),
                    ),
                    ...list.categories.map(
                      (category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ),
                    ),
                  ],
                  onChanged: list.setCategoryFilter,
                ),
              ],
            ),
            if (list.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                list.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Center(
                child: Text('No items yet. Start by creating one!'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _ItemTile(
                    item: item,
                    isSelected: selected?.id == item.id,
                    onEdit: () {
                      widget.listViewModel.selectItem(item.id);
                      widget.formViewModel.loadForEditing(item);
                    },
                    onDelete: () => widget.listViewModel.remove(item.id),
                  );
                },
                separatorBuilder: (context, index) => const Divider(),
                itemCount: items.length,
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.isSelected,
    required this.onEdit,
    required this.onDelete,
  });

  final CatalogItem item;
  final bool isSelected;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final band = QualityScoreCalculator.bandFor(item.score);
    return ListTile(
      selected: isSelected,
      title: Row(
        children: [
          Expanded(
            child: Text(
              item.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: isSelected ? TextDecoration.underline : null,
              ),
            ),
          ),
          QualityBadge(score: item.score, band: band),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.category.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Category: ${item.category}'),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(item.description),
          ),
          if (item.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: item.tags.map((tag) => Chip(label: Text(tag))).toList(),
              ),
            ),
          if (item.isApproved)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: const [
                  Icon(Icons.verified, color: Colors.green, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Approved',
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),
        ],
      ),
      onTap: onEdit,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
