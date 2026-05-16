# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0-beta.1-wip]

### Added

- Extension methods on `FirebaseAuth`:
  `tracedSignInWithEmailAndPassword`,
  `tracedCreateUserWithEmailAndPassword`,
  `tracedSignInAnonymously`,
  `tracedSignInWithCustomToken`,
  `tracedSignInWithCredential`,
  `tracedSignOut`,
  `tracedSendPasswordResetEmail`.
  Each opens a `CLIENT` span named `firebase_auth <op>` with
  `auth.system=firebase`, `auth.operation`, and (when known)
  `auth.provider`.
- On successful sign-in, the resulting user UID is attached as
  `enduser.id` per OTel semconv. Each call accepts
  `recordUserId: false` to skip that if UIDs are treated as PII
  in your environment.
- `FirebaseAuthException`-aware error handling: `error.type` is
  set to the `code` field (e.g. `wrong-password`,
  `user-not-found`) instead of the runtime class name, and the
  exception's `message` becomes the span status description.
  Generic exceptions fall back to runtime-class `error.type`.
- `runWithoutFirebaseAuthInstrumentation` /
  `runWithoutFirebaseAuthInstrumentationAsync` — zone-scoped
  suppression helpers, matching `dartastic_grpc_otel`,
  `dartastic_http_otel`, `dartastic_web_socket_channel_otel`, and
  `dartastic_cloud_firestore_otel`.
- `FirebaseAuthSemantics` — typed attribute-key enum holding
  `auth.system`, `auth.operation`, `auth.provider` until upstream
  semconv covers identity operations natively.
- Tests use `firebase_auth_mocks`; no live Firebase required.
  Coverage: email/password sign-in (with UID capture and the
  opt-out), anonymous sign-in, sign-out, FirebaseAuthException
  error path, suppression scope.
