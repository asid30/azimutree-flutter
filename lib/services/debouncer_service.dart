import 'dart:async';
import 'dart:ui';

/// Delays rapid callbacks so only the latest action is executed.
class DebouncerService {
  final Duration delay;
  Timer? _timer;

  DebouncerService({required this.delay});

  void run(VoidCallback action) {
    _timer?.cancel(); // batalkan yang sebelumnya jika masih aktif
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
