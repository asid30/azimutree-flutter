import 'package:azimutree/views/widgets/alert_dialog_widget/alert_warning_widget.dart';
import 'package:flutter/material.dart';

enum AppAlertType { success, warning, error, info }

Future<void> showAppAlert(
  BuildContext context, {
  required String message,
  required AppAlertType type,
  String? title,
  bool barrierDismissible = false,
}) {
  final resolvedTitle =
      title ??
      switch (type) {
        AppAlertType.success => 'Berhasil',
        AppAlertType.warning => 'Peringatan',
        AppAlertType.error => 'Gagal',
        AppAlertType.info => 'Informasi',
      };
  final backgroundColor = switch (type) {
    AppAlertType.success => Colors.lightGreen.shade200,
    AppAlertType.warning => Colors.orange.shade200,
    AppAlertType.error => Colors.red.shade200,
    AppAlertType.info => Colors.lightBlue.shade100,
  };
  return showDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder:
        (_) => AlertWarningWidget(
          title: resolvedTitle,
          warningMessage: message,
          backgroundColor: backgroundColor,
        ),
  );
}

Future<void> showAppSuccess(
  BuildContext context,
  String message, {
  String title = 'Berhasil',
}) => showAppAlert(
  context,
  message: message,
  type: AppAlertType.success,
  title: title,
);

Future<void> showAppError(
  BuildContext context,
  Object message, {
  String title = 'Gagal',
}) => showAppAlert(
  context,
  message: message.toString(),
  type: AppAlertType.error,
  title: title,
);

Future<void> showAppWarning(
  BuildContext context,
  String message, {
  String title = 'Peringatan',
}) => showAppAlert(
  context,
  message: message,
  type: AppAlertType.warning,
  title: title,
);

Future<void> showAppInfo(
  BuildContext context,
  String message, {
  String title = 'Informasi',
}) => showAppAlert(
  context,
  message: message,
  type: AppAlertType.info,
  title: title,
);
