import 'package:flutter_riverpod/flutter_riverpod.dart';

enum StudentDashboardTab { home, tests, dpp, profile }


class DashboardController extends StateNotifier<StudentDashboardTab> {
  DashboardController() : super(StudentDashboardTab.home);

  void setTab(StudentDashboardTab tab) {
    if (state != tab) {
      state = tab;
    }
  }
}

final dashboardTabProvider =
    StateNotifierProvider<DashboardController, StudentDashboardTab>((ref) {
  return DashboardController();
});
