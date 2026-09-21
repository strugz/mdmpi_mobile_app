import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/b_in_flight_requests.dart';

void main() {
  group('BInFlightRequests.run', () {
    test('two concurrent callers with the same key run the action once',
        () async {
      final inFlight = BInFlightRequests();
      var calls = 0;
      final gate = Completer<List<int>>();

      Future<List<int>> action() {
        calls++;
        return gate.future;
      }

      final first = inFlight.run('k', action);
      final second = inFlight.run('k', action);
      expect(inFlight.isInFlight('k'), isTrue);

      gate.complete([1, 2, 3]);
      final results = await Future.wait([first, second]);

      expect(calls, 1);
      expect(results[0], [1, 2, 3]);
      expect(identical(results[0], results[1]), isTrue,
          reason: 'joined callers share the instance; documented caveat');
    });

    test('different keys do not join', () async {
      final inFlight = BInFlightRequests();
      var calls = 0;
      Future<int> action() async => ++calls;

      await Future.wait([inFlight.run('a', action), inFlight.run('b', action)]);

      expect(calls, 2);
    });

    test('the key is freed after completion so a later call runs again',
        () async {
      final inFlight = BInFlightRequests();
      var calls = 0;
      Future<int> action() async => ++calls;

      await inFlight.run('k', action);
      expect(inFlight.isInFlight('k'), isFalse);
      await inFlight.run('k', action);

      expect(calls, 2);
    });

    test('a thrown error reaches every joined caller and frees the key',
        () async {
      final inFlight = BInFlightRequests();
      final gate = Completer<int>();
      Future<int> action() => gate.future;

      final first = inFlight.run('k', action);
      final second = inFlight.run('k', action);
      gate.completeError(StateError('boom'));

      await expectLater(first, throwsStateError);
      await expectLater(second, throwsStateError);
      expect(inFlight.isInFlight('k'), isFalse);
    });

    test('isAnyInFlight matches on prefix', () async {
      final inFlight = BInFlightRequests();
      final gate = Completer<int>();

      final pending = inFlight.run('getAll:Today:true', () => gate.future);
      expect(inFlight.isAnyInFlight('getAll:Today'), isTrue);
      expect(inFlight.isAnyInFlight('getAll:All'), isFalse);

      gate.complete(1);
      await pending;
      expect(inFlight.isAnyInFlight('getAll:'), isFalse);
    });
  });
}
