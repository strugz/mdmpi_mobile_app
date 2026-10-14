import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/visit_location.dart';

/// The location stamped on every saved engagement: never blocks a save,
/// asks once per session, reuses a recent fix, and says why when it has
/// none.
void main() {
  var clock = DateTime.utc(2026, 10, 14, 2);
  late int fixCalls;
  late int requests;
  late LocationPermission permission;
  late bool serviceOn;
  VisitFix? nextFix;

  BVisitLocation make({VisitFix? lastKnown, bool supported = true}) =>
      BVisitLocation(
        supported: supported,
        now: () => clock,
        serviceEnabled: () async => serviceOn,
        checkPermission: () async => permission,
        requestPermission: () async {
          requests++;
          return permission;
        },
        currentFix: (_) async {
          fixCalls++;
          return nextFix;
        },
        lastKnownFix: () async => lastKnown,
      );

  setUp(() {
    clock = DateTime.utc(2026, 10, 14, 2);
    fixCalls = 0;
    requests = 0;
    permission = LocationPermission.whileInUse;
    serviceOn = true;
    nextFix = VisitFix(
        latitude: 14.5547,
        longitude: 121.0244,
        accuracy: 12,
        at: DateTime.utc(2026, 10, 14, 2));
  });

  test('a fix goes up with its time and OK', () async {
    final f = await make().fields();
    expect(f, {
      'Latitude': 14.5547,
      'Longitude': 121.0244,
      'LocationAccuracy': 12.0,
      'LocationAt': '2026-10-14T02:00:00.000Z',
      'LocationStatus': 'OK',
    });
  });

  test('a batch asks once: a recent fix is reused, an old one is not',
      () async {
    final loc = make();
    await loc.fields();
    clock = clock.add(const Duration(seconds: 90));
    await loc.fields();
    expect(fixCalls, 1);
    clock = clock.add(const Duration(minutes: 5));
    await loc.fields();
    expect(fixCalls, 2);
  });

  test('no current fix: the last known one, else UNAVAILABLE', () async {
    nextFix = null;
    final known = VisitFix(
        latitude: 1, longitude: 2, accuracy: 50, at: DateTime.utc(2026));
    expect((await make(lastKnown: known).fields())['Latitude'], 1);
    expect(await make().fields(), {'LocationStatus': 'UNAVAILABLE'});
  });

  test('refused: DENIED, and asked only once per session', () async {
    permission = LocationPermission.denied;
    final loc = make();
    expect(await loc.fields(), {'LocationStatus': 'DENIED'});
    expect(await loc.fields(), {'LocationStatus': 'DENIED'});
    expect(requests, 1);
    expect(fixCalls, 0);
  });

  test('location switched off: OFF', () async {
    serviceOn = false;
    expect(await make().fields(), {'LocationStatus': 'OFF'});
  });

  test('not Android: nothing is added', () async {
    expect(await make(supported: false).fields(), isEmpty);
    expect(
        await make(supported: false).state(), VisitLocationState.unsupported);
  });

  test('a failure never escapes a save', () async {
    final loc = BVisitLocation(
        supported: true,
        serviceEnabled: () async => throw StateError('plugin'));
    expect(await loc.fields(), {'LocationStatus': 'UNAVAILABLE'});
  });

  test('Settings reads the state truthfully', () async {
    expect(await make().state(), VisitLocationState.on);
    permission = LocationPermission.deniedForever;
    expect(await make().state(), VisitLocationState.blocked);
    permission = LocationPermission.denied;
    expect(await make().state(), VisitLocationState.needsPermission);
    serviceOn = false;
    expect(await make().state(), VisitLocationState.serviceOff);
  });
}
