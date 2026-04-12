---
name: project-feedback
description: Guide for showing user feedback using duskmoon_ui package - toasts, snackbars, dialogs, bottom sheets (project)
---

# Flutter User Feedback Skill

This skill guides the implementation of user feedback UI using the `duskmoon_ui` package (via `duskmoon_feedback`) for toasts, snackbars, dialogs, and bottom sheets.

## When to Use

Trigger this skill when:
- Showing success/error messages to users
- Displaying confirmation dialogs
- Implementing bottom sheet actions
- User asks to "show toast", "add notification", "display error", "confirm action"

## Package Import

```dart
import 'package:duskmoon_ui/duskmoon_ui.dart';
```

## Success and Error Toasts

### Success Toast

```dart
showDmSuccessToast(
  context: context,
  message: 'Item saved successfully!',
  title: 'Success',  // Optional, defaults to localized "Success"
  duration: const Duration(seconds: 5),
  showCloseIcon: false,
  // Optional action button
  actionLabel: 'View',
  onActionPressed: () => navigateToItem(),
);
```

### Error Toast

Error toasts **stay visible until user dismisses** them (no auto-dismiss).
The message text is **selectable** so users can copy error details.

```dart
showDmErrorToast(
  context: context,
  message: 'Failed to save item. Please try again.',
  title: 'Error',  // Optional, defaults to localized "Error"
  // Optional action button
  actionLabel: 'Retry',
  onActionPressed: () => retryOperation(),
);
```

**Note:** Unlike success toasts, error toasts:
- Always show close icon (user must dismiss)
- Have selectable message text (for copying error details)
- Don't auto-dismiss (important errors shouldn't disappear)

## Snackbars

### Basic Snackbar

```dart
showDmSnackbar(
  context: context,
  message: const Text('Operation completed'),
  duration: const Duration(seconds: 5),
  showCloseIcon: false,
  actionLabel: 'Undo',
  onActionPressed: () => undoOperation(),
);
```

### Undo Snackbar

For destructive operations with undo capability:

```dart
showDmUndoSnackbar(
  context: context,
  message: const Text('Item deleted'),
  onUndoPressed: () {
    // Restore the deleted item
    restoreItem();
  },
  duration: const Duration(seconds: 5),
  showCloseIcon: true,
);
```

## Dialogs

### Adaptive Alert Dialog

Shows Material dialog on Android/Linux/Windows, Cupertino dialog on iOS/macOS:

```dart
final result = await showDmDialog<bool>(
  context: context,
  title: const Text('Confirm Delete'),
  content: const Text('Are you sure you want to delete this item?'),
  actions: [
    DmDialogAction(
      onPressed: (context) => Navigator.of(context).pop(false),
      child: const Text('Cancel'),
    ),
    DmDialogAction(
      onPressed: (context) => Navigator.of(context).pop(true),
      child: const Text('Delete'),
    ),
  ],
);

if (result == true) {
  deleteItem();
}
```

### DmDialogAction

Platform-adaptive dialog button:

```dart
DmDialogAction(
  onPressed: (context) {
    // Handle action
    Navigator.of(context).pop(result);
  },
  child: const Text('Action'),
)
```

## Full Screen Dialog

For complex forms or content that needs full screen:

```dart
showDmFullscreenDialog(
  context: context,
  title: const Text('Edit Profile'),
  builder: (context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(decoration: InputDecoration(labelText: 'Name')),
          TextField(decoration: InputDecoration(labelText: 'Email')),
          // ... more form fields
        ],
      ),
    );
  },
);
```

## Bottom Sheet Actions

For presenting a list of actions at the bottom of the screen:

```dart
showDmBottomSheetActionList(
  context: context,
  showBackdrop: true,  // Dim background and close on tap outside
  actions: [
    DmBottomSheetAction(
      title: const Text('Take Photo'),
      onTap: () => takePhoto(),
    ),
    DmBottomSheetAction(
      title: const Text('Choose from Gallery'),
      onTap: () => pickFromGallery(),
    ),
    DmBottomSheetAction(
      title: const Text('Cancel'),
      onTap: () {},  // Just closes the sheet
      style: ElevatedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
    ),
  ],
);
```

### Custom DmBottomSheetAction Style

```dart
DmBottomSheetAction(
  title: const Text('Delete'),
  onTap: () => deleteItem(),
  style: ElevatedButton.styleFrom(
    foregroundColor: Theme.of(context).colorScheme.onError,
    backgroundColor: Theme.of(context).colorScheme.error,
  ),
)
```

## Helper Utilities

### Global ScaffoldMessenger Key

For showing snackbars from anywhere in the app:

```dart
// In app setup
MaterialApp(
  scaffoldMessengerKey: dmScaffoldMessengerKey,
  // ...
)

// Then anywhere in the app
dmScaffoldMessengerKey.currentState?.showSnackBar(
  SnackBar(content: Text('Message')),
);
```

### Get Widget Size

```dart
final GlobalKey myKey = GlobalKey();

// Later...
final size = getDmWidgetSize(myKey);
if (size != null) {
  print('Width: ${size.width}, Height: ${size.height}');
}
```

## Complete Example: Form Submission

```dart
Future<void> _submitForm() async {
  try {
    setState(() => _isLoading = true);

    await api.submitData(formData);

    if (mounted) {
      showDmSuccessToast(
        context: context,
        message: 'Your changes have been saved.',
      );
      Navigator.of(context).pop();
    }
  } catch (e) {
    if (mounted) {
      showDmErrorToast(
        context: context,
        message: e.toString(),
        actionLabel: 'Retry',
        onActionPressed: _submitForm,
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

## Complete Example: Delete with Confirmation

```dart
Future<void> _deleteItem(Item item) async {
  final confirmed = await showDmDialog<bool>(
    context: context,
    title: const Text('Delete Item'),
    content: Text('Are you sure you want to delete "${item.name}"?'),
    actions: [
      DmDialogAction(
        onPressed: (ctx) => Navigator.of(ctx).pop(false),
        child: const Text('Cancel'),
      ),
      DmDialogAction(
        onPressed: (ctx) => Navigator.of(ctx).pop(true),
        child: const Text('Delete'),
      ),
    ],
  );

  if (confirmed != true) return;

  // Optimistically remove from UI
  setState(() => _items.remove(item));

  showDmUndoSnackbar(
    context: context,
    message: Text('"${item.name}" deleted'),
    onUndoPressed: () {
      // Restore item
      setState(() => _items.add(item));
    },
  );

  // Actually delete after undo window
  await Future.delayed(const Duration(seconds: 5));
  if (_items.contains(item)) return; // Was undone

  try {
    await api.deleteItem(item.id);
  } catch (e) {
    // Restore on failure
    setState(() => _items.add(item));
    showDmErrorToast(
      context: context,
      message: 'Failed to delete item',
    );
  }
}
```

## Best Practices

1. **Use success/error toasts** for operation results
2. **Use undo snackbar** for destructive actions (delete, archive)
3. **Use dialogs** for confirmations requiring user decision
4. **Use bottom sheets** for action menus or pickers
5. **Use full screen dialog** for complex forms
6. **Always check `mounted`** before showing feedback in async operations
7. **Provide action buttons** for error recovery (retry)
8. **Keep messages concise** - users scan quickly
9. **Use appropriate duration** - longer for errors, shorter for success
