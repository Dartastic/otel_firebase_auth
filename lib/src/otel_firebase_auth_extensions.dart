// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_auth_semantics.dart';
import 'firebase_auth_suppression.dart';

const _tracerName = 'otel_firebase_auth';
const _authSystem = 'firebase';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

Attributes _baseAttrs({required String operation, String? provider}) {
  final m = <String, Object>{
    FirebaseAuthSemantics.system.key: _authSystem,
    FirebaseAuthSemantics.operation.key: operation,
  };
  if (provider != null) m[FirebaseAuthSemantics.provider.key] = provider;
  return OTel.attributesFromMap(m);
}

void _attachUserId(APISpan? span, UserCredential cred) {
  final uid = cred.user?.uid;
  if (uid == null || uid.isEmpty || span == null) return;
  span.addAttributes(OTel.attributes([
    OTel.attributeString(Enduser.enduserId.key, uid),
  ]));
}

/// Runs [op] inside a CLIENT span with the standard `auth.*`
/// attributes. On exception: status flipped to Error in OTel-spec
/// order (recordException → setStatus); the original error is
/// rethrown. In a suppressed zone, calls [op] with `null` and emits
/// no span.
Future<R> _traced<R>(
  String operation, {
  required Future<R> Function(APISpan? span) op,
  String? provider,
}) async {
  if (firebaseAuthInstrumentationSuppressed()) return op(null);
  final span = _tracer().startSpan(
    'firebase_auth $operation',
    kind: SpanKind.client,
    attributes: _baseAttrs(operation: operation, provider: provider),
  );
  try {
    return await op(span);
  } on FirebaseAuthException catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(ErrorResource.errorType.key, e.code),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.message ?? e.code);
    rethrow;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

/// Traced operations on [FirebaseAuth].
///
/// Each call opens a `CLIENT` span named `firebase_auth <op>` with
/// `auth.system=firebase`, `auth.operation=<op>`, and (when known)
/// `auth.provider`. On successful sign-in, the returned user's UID
/// is attached as `enduser.id` — set `recordUserId: false` on each
/// call to skip that if you treat UIDs as PII.
extension OTelFirebaseAuth on FirebaseAuth {
  /// Traced `signInWithEmailAndPassword`.
  Future<UserCredential> tracedSignInWithEmailAndPassword({
    required String email,
    required String password,
    bool recordUserId = true,
  }) {
    return _traced<UserCredential>(
      'sign_in',
      provider: 'password',
      op: (span) async {
        final cred = await signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (recordUserId) _attachUserId(span, cred);
        return cred;
      },
    );
  }

  /// Traced `createUserWithEmailAndPassword`.
  Future<UserCredential> tracedCreateUserWithEmailAndPassword({
    required String email,
    required String password,
    bool recordUserId = true,
  }) {
    return _traced<UserCredential>(
      'create_user',
      provider: 'password',
      op: (span) async {
        final cred = await createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (recordUserId) _attachUserId(span, cred);
        return cred;
      },
    );
  }

  /// Traced `signInAnonymously`.
  Future<UserCredential> tracedSignInAnonymously({
    bool recordUserId = true,
  }) {
    return _traced<UserCredential>(
      'sign_in',
      provider: 'anonymous',
      op: (span) async {
        final cred = await signInAnonymously();
        if (recordUserId) _attachUserId(span, cred);
        return cred;
      },
    );
  }

  /// Traced `signInWithCustomToken`.
  Future<UserCredential> tracedSignInWithCustomToken(
    String token, {
    bool recordUserId = true,
  }) {
    return _traced<UserCredential>(
      'sign_in',
      provider: 'custom_token',
      op: (span) async {
        final cred = await signInWithCustomToken(token);
        if (recordUserId) _attachUserId(span, cred);
        return cred;
      },
    );
  }

  /// Traced `signInWithCredential`. The credential's `providerId`
  /// is surfaced as the `auth.provider` attribute.
  Future<UserCredential> tracedSignInWithCredential(
    AuthCredential credential, {
    bool recordUserId = true,
  }) {
    return _traced<UserCredential>(
      'sign_in',
      provider: credential.providerId,
      op: (span) async {
        final cred = await signInWithCredential(credential);
        if (recordUserId) _attachUserId(span, cred);
        return cred;
      },
    );
  }

  /// Traced `signOut`.
  Future<void> tracedSignOut() {
    return _traced<void>('sign_out', op: (_) => signOut());
  }

  /// Traced `sendPasswordResetEmail`.
  Future<void> tracedSendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) {
    return _traced<void>(
      'send_password_reset',
      provider: 'password',
      op: (_) => sendPasswordResetEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      ),
    );
  }
}
