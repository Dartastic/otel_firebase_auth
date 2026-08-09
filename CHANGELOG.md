# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-08-09

### Changed

- Semantic conventions aligned with the current OTel registry:
  `enduser.id` and `error.type` come from the API's semconv enums;
  the not-yet-registered `auth.*` keys live in the typed
  `FirebaseAuthSemantics` enum (no raw string keys emitted).
- Dependency floors raised to `dartastic_opentelemetry ^1.1.0-beta.12` and
  `dartastic_opentelemetry_api ^1.0.0-rc.1`. The previous floors declared
  compatibility with API versions that predate the semconv enums this
  package uses and could not actually resolve-and-compile.
- `repository` URL corrected to the canonical `Dartastic` org casing so
  pub.dev repository verification succeeds.
- `firebase_auth` floor raised to `^6.0.0` (latest major;
  `firebase_auth_mocks` to `^0.15.0` to match). Analyzer and the full
  test suite verified at both the `6.0.0` lower bound and the current
  `6.5.7`.

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
  suppression helpers, matching `otel_grpc`, `otel_http`,
  `otel_web_socket_channel`, and `otel_cloud_firestore`.
- `FirebaseAuthSemantics` — typed attribute-key enum holding
  `auth.system`, `auth.operation`, `auth.provider` until upstream
  semconv covers identity operations natively.
- Tests use `firebase_auth_mocks`; no live Firebase required.
  Coverage: email/password sign-in (with UID capture and the
  opt-out), anonymous sign-in, sign-out, FirebaseAuthException
  error path, suppression scope.
