import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

enum PermissionOnboardingState {
  notStarted,
  explaining,
  requesting,
  granted,
  denied,
  permanentlyDenied,
}

class PermissionOnboardingNotifier
    extends StateNotifier<PermissionOnboardingState> {
  PermissionOnboardingNotifier() : super(PermissionOnboardingState.notStarted);

  Future<void> showExplanation() async {
    state = PermissionOnboardingState.explaining;
  }

  Future<bool> requestSmsPermission() async {
    state = PermissionOnboardingState.requesting;
    final status = await Permission.sms.request();

    if (status.isGranted) {
      state = PermissionOnboardingState.granted;
      return true;
    } else if (status.isPermanentlyDenied) {
      state = PermissionOnboardingState.permanentlyDenied;
      return false;
    } else if (status.isDenied) {
      state = PermissionOnboardingState.denied;
      return false;
    }
    return false;
  }

  Future<void> skipPermissionForNow() async {
    state = PermissionOnboardingState.denied;
  }

  void reset() {
    state = PermissionOnboardingState.notStarted;
  }
}

final permissionOnboardingProvider = StateNotifierProvider<
    PermissionOnboardingNotifier,
    PermissionOnboardingState>((ref) => PermissionOnboardingNotifier());
