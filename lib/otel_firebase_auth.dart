// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

/// OpenTelemetry instrumentation for `package:firebase_auth`.
///
/// Adds `tracedSignIn*`, `tracedCreateUserWithEmailAndPassword`,
/// `tracedSignOut`, and `tracedSendPasswordResetEmail` as extension
/// methods on [FirebaseAuth]. Each opens a CLIENT span with
/// `auth.system=firebase` and (on successful sign-in) the resulting
/// UID as `enduser.id`.
library;

export 'src/firebase_auth_semantics.dart';
export 'src/firebase_auth_suppression.dart';
export 'src/otel_firebase_auth_extensions.dart';
