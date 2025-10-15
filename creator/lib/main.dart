import 'package:flutter/material.dart';

import 'api/local_item_api.dart';
import 'features/items/application/item_service.dart';
import 'features/items/data/in_memory_item_repository.dart';
import 'features/items/presentation/pages/item_creator_page.dart';
import 'features/items/presentation/viewmodels/item_form_view_model.dart';
import 'features/items/presentation/viewmodels/item_list_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = InMemoryItemRepository();
  final service = ItemService(repository);
  final api = LocalItemApi(service);
  await api.start();
  runApp(CreatorApp(itemService: service));
}

class CreatorApp extends StatefulWidget {
  const CreatorApp({required this.itemService, super.key});

  final ItemService itemService;

  @override
  State<CreatorApp> createState() => _CreatorAppState();
}

class _CreatorAppState extends State<CreatorApp> {
  late final ItemListViewModel _listViewModel;
  late final ItemFormViewModel _formViewModel;

  @override
  void initState() {
    super.initState();
    _listViewModel = ItemListViewModel(widget.itemService);
    _formViewModel = ItemFormViewModel(widget.itemService);
  }

  @override
  void dispose() {
    _listViewModel.dispose();
    _formViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catalog Creator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: ItemCreatorPage(
        listViewModel: _listViewModel,
        formViewModel: _formViewModel,
      ),
    );
  }
}
