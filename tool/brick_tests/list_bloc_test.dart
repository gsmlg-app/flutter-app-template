import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import 'test_utils.dart';

/// Tests for the list_bloc brick
void main() {
  group('List BLoC Brick Tests', () {
    late TestDirectory tempDir;

    setUp(() async {
      tempDir = await TestDirectory.create();
    });

    tearDown(() async {
      await tempDir.cleanup();
    });

    test('generates comprehensive list BLoC with all features', () async {
      final config = {
        'name': 'Users',
        'item_type': 'User',
        'has_pagination': true,
        'has_search': true,
        'has_filters': true,
        'has_reorder': true,
        'has_crud': true,
        'filter_types': ['category', 'status', 'brand'],
        'sort_options': ['name', 'date', 'price'],
        'output_directory': 'app_bloc',
      };

      final result = await runMasonBrick('list_bloc', config, tempDir.path);
      expect(result.exitCode, equals(0));

      final basePath = '${tempDir.path}/app_bloc/users_list_bloc';
      
      // Check main files
      expect(File('$basePath/lib/users_list_bloc.dart').existsSync(), isTrue);
      expect(File('$basePath/lib/src/bloc.dart').existsSync(), isTrue);
      expect(File('$basePath/lib/src/event.dart').existsSync(), isTrue);
      expect(File('$basePath/lib/src/state.dart').existsSync(), isTrue);
      expect(File('$basePath/lib/src/schema.dart').existsSync(), isTrue);
      expect(File('$basePath/lib/src/item_state.dart').existsSync(), isTrue);
      expect(File('$basePath/test/users_list_bloc_test.dart').existsSync(), isTrue);
      expect(File('$basePath/pubspec.yaml').existsSync(), isTrue);

      // Check BLoC content
      final blocContent = await File('$basePath/lib/src/bloc.dart').readAsString();
      expect(blocContent, contains('class UsersListBloc extends Bloc<UsersListEvent, UsersListState>'));
      expect(blocContent, contains('abstract class UsersListRepository'));
      expect(blocContent, contains('Future<List<User>> fetchItems'));
      expect(blocContent, contains('Future<User> createItem'));
      expect(blocContent, contains('Future<void> deleteItem'));

      // Check schema content
      final schemaContent = await File('$basePath/lib/src/schema.dart').readAsString();
      expect(schemaContent, contains('class UsersListSchema'));
      expect(schemaContent, contains('class FieldSchema'));
      expect(schemaContent, contains('category'));
      expect(schemaContent, contains('status'));
      expect(schemaContent, contains('brand'));
    });

    test('generates minimal list BLoC without optional features', () async {
      final config = {
        'name': 'Tasks',
        'item_type': 'Task',
        'has_pagination': false,
        'has_search': false,
        'has_filters': false,
        'has_reorder': false,
        'has_crud': false,
        'filter_types': [],
        'sort_options': [],
        'output_directory': 'app_bloc',
      };

      final result = await runMasonBrick('list_bloc', config, tempDir.path);
      expect(result.exitCode, equals(0));

      final basePath = '${tempDir.path}/app_bloc/tasks_list_bloc';
      expect(File('$basePath/lib/src/bloc.dart').existsSync(), isTrue);

      final blocContent = await File('$basePath/lib/src/bloc.dart').readAsString();
      expect(blocContent, contains('class TasksListBloc'));
      expect(blocContent, contains('Future<List<Task>> fetchAllItems'));
      expect(blocContent, isNot(contains('fetchItems')));
      expect(blocContent, isNot(contains('createItem')));
    });

    test('generates proper event classes with all features', () async {
      final config = {
        'name': 'Products',
        'item_type': 'Product',
        'has_pagination': true,
        'has_search': true,
        'has_filters': true,
        'has_reorder': true,
        'has_crud': true,
        'filter_types': ['category'],
        'sort_options': ['name'],
        'output_directory': 'app_bloc',
      };

      final result = await runMasonBrick('list_bloc', config, tempDir.path);
      expect(result.exitCode, equals(0));

      final eventContent = await File('${tempDir.path}/app_bloc/products_list_bloc/lib/src/event.dart').readAsString();
      
      expect(eventContent, contains('class ProductsListEvent'));
      expect(eventContent, contains('ProductsListEventInitialize'));
      expect(eventContent, contains('ProductsListEventLoadMore'));
      expect(eventContent, contains('ProductsListEventSearch'));
      expect(eventContent, contains('ProductsListEventSetFilter'));
      expect(eventContent, contains('ProductsListEventReorderItems'));
      expect(eventContent, contains('ProductsListEventCreateItem'));
      expect(eventContent, contains('ProductsListEventUpdateItem'));
      expect(eventContent, contains('ProductsListEventDeleteItem'));
    });

    test('generates comprehensive state management', () async {
      final config = {
        'name': 'Orders',
        'item_type': 'Order',
        'has_pagination': true,
        'has_search': true,
        'has_filters': true,
        'has_reorder': false,
        'has_crud': true,
        'filter_types': ['status'],
        'sort_options': ['date'],
        'output_directory': 'app_bloc',
      };

      final result = await runMasonBrick('list_bloc', config, tempDir.path);
      expect(result.exitCode, equals(0));

      final stateContent = await File('${tempDir.path}/app_bloc/orders_list_bloc/lib/src/state.dart').readAsString();
      
      expect(stateContent, contains('class OrdersListState'));
      expect(stateContent, contains('List<Order> items'));
      expect(stateContent, contains('OrdersListStatus status'));
      expect(stateContent, contains('Map<String, OrderItemState> itemStates'));
      expect(stateContent, contains('OrdersListSchema schema'));
      expect(stateContent, contains('String searchQuery'));
      expect(stateContent, contains('Map<String, String> filters'));
    });

    test('generates item state tracking', () async {
      final config = {
        'name': 'Comments',
        'item_type': 'Comment',
        'has_pagination': false,
        'has_search': false,
        'has_filters': false,
        'has_reorder': false,
        'has_crud': true,
        'filter_types': [],
        'sort_options': [],
        'output_directory': 'app_bloc',
      };

      final result = await runMasonBrick('list_bloc', config, tempDir.path);
      expect(result.exitCode, equals(0));

      final itemStateContent = await File('${tempDir.path}/app_bloc/comments_list_bloc/lib/src/item_state.dart').readAsString();
      
      expect(itemStateContent, contains('class CommentItemState'));
      expect(itemStateContent, contains('CommentItemStatus status'));
      expect(itemStateContent, contains('bool isUpdating'));
      expect(itemStateContent, contains('bool isRemoving'));
      expect(itemStateContent, contains('bool isSelected'));
      expect(itemStateContent, contains('bool isExpanded'));
      expect(itemStateContent, contains('bool isEditing'));
      expect(itemStateContent, contains('String? error'));
    });

    test('generates comprehensive test suite', () async {
      final config = {
        'name': 'Notifications',
        'item_type': 'Notification',
        'has_pagination': true,
        'has_search': true,
        'has_filters': true,
        'has_reorder': true,
        'has_crud': true,
        'filter_types': ['type', 'read'],
        'sort_options': ['date', 'priority'],
        'output_directory': 'app_bloc',
      };

      final result = await runMasonBrick('list_bloc', config, tempDir.path);
      expect(result.exitCode, equals(0));

      final testContent = await File('${tempDir.path}/app_bloc/notifications_list_bloc/test/notifications_list_bloc_test.dart').readAsString();
      
      expect(testContent, contains('import \'package:bloc_test/bloc_test.dart\';'));
      expect(testContent, contains('group(\'NotificationsListBloc\', () {'));
      expect(testContent, contains('blocTest<NotificationsListBloc, NotificationsListState>'));
      expect(testContent, contains('emits [NotificationsListStateLoading'));
      expect(testContent, contains('NotificationsListStateLoaded'));
    });

    test('validates required parameters', () async {
      final config = {
        'item_type': 'User',
        'has_pagination': true,
        'has_search': true,
        'has_filters': true,
        'has_reorder': true,
        'has_crud': true,
        'filter_types': ['category'],
        'sort_options': ['name'],
        'output_directory': 'app_bloc',
      };

      final result = await runMasonBrick('list_bloc', config, tempDir.path);
      expect(result.exitCode, isNot(equals(0)));
    });

    test('handles custom output directory', () async {
      final config = {
        'name': 'Documents',
        'item_type': 'Document',
        'has_pagination': false,
        'has_search': false,
        'has_filters': false,
        'has_reorder': false,
        'has_crud': false,
        'filter_types': [],
        'sort_options': [],
        'output_directory': 'custom_bloc',
      };

      final result = await runMasonBrick('list_bloc', config, tempDir.path);
      expect(result.exitCode, equals(0));

      final basePath = '${tempDir.path}/custom_bloc/documents_list_bloc';
      expect(File('$basePath/lib/documents_list_bloc.dart').existsSync(), isTrue);
    });
  });
}