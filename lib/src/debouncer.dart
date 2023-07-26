import 'dart:async';

class Debounce {
  Timer? _timer;
  Debounce();

  void dispose() {
    _timer?.cancel();
  }

  void call(Function callback, [int delay = 400]) {
    _timer?.cancel();

    _timer = Timer(Duration(milliseconds: delay), () async {
      callback();
      _timer?.cancel();
    });
  }
}
