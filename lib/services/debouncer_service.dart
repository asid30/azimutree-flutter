import 'dart:async';
import 'dart:ui';

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
