// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'dart:async';

/// Zone key used to mark a region of code as "do not instrument
/// Firebase Auth calls." `Symbol`-keyed so the value can't collide
/// with other packages' zone values.
const Symbol _suppressKey = #otel_firebase_auth_suppress;

/// Returns `true` when the current zone has opted out of Firebase
/// Auth OTel instrumentation.
bool firebaseAuthInstrumentationSuppressed() {
  return Zone.current[_suppressKey] == true;
}

/// Runs [body] in a zone where the traced extension methods become
/// transparent passthroughs.
///
/// Mirrors the pattern used by `otel_grpc`,
/// `otel_http`, and the Firestore wrapper. Safe to nest.
T runWithoutFirebaseAuthInstrumentation<T>(T Function() body) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}

/// Async variant of [runWithoutFirebaseAuthInstrumentation].
Future<T> runWithoutFirebaseAuthInstrumentationAsync<T>(
  Future<T> Function() body,
) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}
