import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../constants/app_colors.dart';

class ToastUtils {
  ToastUtils._();

  static final FToast _fToast = FToast();

  static void _init(BuildContext context) {
    _fToast.init(context);
  }

  /// Shows a styled toast with context. Preferred for beautiful UI.
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    bool isSuccess = false,
    bool aboveNavBar = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    _init(context);
    _fToast.removeCustomToast();

    Color bgColor = AppColors.ink;
    Color textColor = Colors.white;
    IconData icon = Icons.info_outline;

    if (isError) {
      bgColor = AppColors.error;
      icon = Icons.error_outline;
    } else if (isSuccess) {
      bgColor = AppColors.success;
      icon = Icons.check_circle_outline;
    }

    Widget toast = Container(
      margin: EdgeInsets.only(bottom: aboveNavBar ? 100.0 : 0.0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: bgColor.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
        ],
      ),
    );

    _fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: duration,
    );
  }

  /// Shows a success toast
  static void showSuccess(BuildContext context, String message, {bool aboveNavBar = false}) {
    show(context, message: message, isSuccess: true, aboveNavBar: aboveNavBar);
  }

  /// Shows an error toast
  static void showError(BuildContext context, String message, {bool aboveNavBar = false}) {
    show(context, message: message, isError: true, aboveNavBar: aboveNavBar);
  }

  /// Shows an info/standard toast
  static void showInfo(BuildContext context, String message, {bool aboveNavBar = false}) {
    show(context, message: message, aboveNavBar: aboveNavBar);
  }

  /// Native toast fallback if BuildContext is not available
  static void showNative({
    required String message,
    bool isError = false,
    bool isSuccess = false,
  }) {
    Color bgColor = AppColors.ink;
    if (isError) {
      bgColor = AppColors.error;
    } else if (isSuccess) {
      bgColor = AppColors.success;
    }

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: bgColor,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  /// Native success fallback
  static void showNativeSuccess(String message) {
    showNative(message: message, isSuccess: true);
  }

  /// Native error fallback
  static void showNativeError(String message) {
    showNative(message: message, isError: true);
  }
}
