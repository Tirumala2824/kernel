// Test-only helpers shared by the in-memory doubles.

import 'dart:async';

/// Broadcast change signal with "emit current value on listen" semantics,
/// like a drift watch query.
class Changes {
  final _controller = StreamController<void>.broadcast(sync: true);

  void notify() => _controller.add(null);

  Stream<void> get stream => _controller.stream;

  // onCancel deliberately returns void: returning the broadcast
  // subscription's cancel future (a root-zone future) would stall
  // `Stream.first` under the widget-test FakeAsync zone.
  Stream<T> watch<T>(T Function() read) => Stream<T>.multi((sink) {
    sink.add(read());
    final sub = _controller.stream.listen((_) => sink.add(read()));
    sink.onCancel = () {
      sub.cancel();
    };
  });
}

int _seq = 0;

/// Sequential test id with a readable prefix.
String testId(String prefix) => '$prefix-${++_seq}';
