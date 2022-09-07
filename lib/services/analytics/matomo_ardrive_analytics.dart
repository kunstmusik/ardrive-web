import 'package:matomo_tracker/matomo_tracker.dart';

import 'ardrive_analytics.dart';

class MatomoArDriveAnalytics extends ArDriveAnalytics {
  @override
  void trackScreenEvent({
    required String screenName,
    required String eventName,
    Map<String, dynamic> dimensions = const {},
    Map<String, num> metrics = const {},
  }) {
    MatomoTracker.instance.trackEvent(
      eventCategory: screenName,
      action: eventName,
      eventValue: 1,
    );
  }

  @override
  void trackEvent({
    required String eventName,
    Map<String, dynamic> dimensions = const {},
    Map<String, num> metrics = const {},
  }) {
    MatomoTracker.instance.trackEvent(
      eventCategory: eventName,
      action: eventName,
      eventValue: 2,
    );
  }

  @override
  void setUserId(String userId) {
    MatomoTracker.instance.setVisitorUserId(userId);
  }

  @override
  void clearUserId() {
    print("[A8s] Cleared user ID");
  }
}
