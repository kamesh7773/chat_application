class DateTimeCalculatorForUsers {
  static String getLastActiveTime({required DateTime lastSeen, required bool isOnline}) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (isOnline) {
      return "online";
    } else if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return 'Active ${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return 'Active ${difference.inHours} hr ago';
    } else if (difference.inDays < 7) {
      return 'Active ${difference.inDays} days ago';
    } else {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? 'Active 1 week ago' : 'Active $weeks weeks ago';
    }
  }
}
