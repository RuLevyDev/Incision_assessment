import 'package:creator/core/errors/validation_exception.dart';
import '../value_objects/item_draft.dart';

class ItemValidator {
  static final RegExp _invalidChars = RegExp(r'[!@#\$%^&*()_=+\[\]{};:"\\|<>/?~]');

  static void validate(ItemDraft draft) {
    final errors = <String, String>{};

    if (draft.title.trim().isEmpty) {
      errors['title'] = 'Title is required.';
    } else if (_invalidChars.hasMatch(draft.title)) {
      errors['title'] = 'Title contains forbidden characters.';
    }

    if (draft.description.trim().isEmpty) {
      errors['description'] = 'Description is required.';
    } else if (_invalidChars.hasMatch(draft.description)) {
      errors['description'] = 'Description contains forbidden characters.';
    }

    if (draft.category.trim().isNotEmpty && _invalidChars.hasMatch(draft.category)) {
      errors['category'] = 'Category contains forbidden characters.';
    }

    final hasInvalidTag = draft.tags.any((tag) => tag.trim().isEmpty || _invalidChars.hasMatch(tag));
    if (draft.tags.isNotEmpty && hasInvalidTag) {
      errors['tags'] = 'Tags cannot be empty or contain forbidden characters.';
    }

    if (errors.isNotEmpty) {
      throw ValidationException(errors);
    }
  }
}
