import 'package:flutter/material.dart';
import 'custom_button.dart';

class CustomDialog {
  CustomDialog._();

  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            message,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
          actions: <Widget>[
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: cancelLabel,
                    isPrimary: false,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: confirmLabel,
                    backgroundColor: isDestructive ? theme.colorScheme.error : null,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  static Future<String?> showInputDialog({
    required BuildContext context,
    required String title,
    required String hintText,
    String? initialValue,
    String confirmLabel = 'Save',
    String cancelLabel = 'Cancel',
  }) {
    final theme = Theme.of(context);
    final textController = TextEditingController(text: initialValue);

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: hintText,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
          actions: <Widget>[
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: cancelLabel,
                    isPrimary: false,
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: confirmLabel,
                    onPressed: () => Navigator.of(context).pop(textController.text.trim()),
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  static void showLoading({
    required BuildContext context,
    required String message,
  }) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
