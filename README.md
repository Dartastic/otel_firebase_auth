# otel_firebase_auth

OpenTelemetry instrumentation for
[`package:firebase_auth`](https://pub.dev/packages/firebase_auth),
built on the
[Dartastic OpenTelemetry SDK](https://pub.dev/packages/dartastic_opentelemetry).

Adds `traced*` extension methods on `FirebaseAuth` so every sign-in,
sign-out, and user-management call emits a `CLIENT` span carrying
the OTel identity (`auth.*` + `enduser.*`) semconv attributes.

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:otel_firebase_auth/otel_firebase_auth.dart';

final auth = FirebaseAuth.instance;

// Sign in
final cred = await auth.tracedSignInWithEmailAndPassword(
  email: 'alice@example.com',
  password: 'pw',
);

// Create user
await auth.tracedCreateUserWithEmailAndPassword(
  email: 'bob@example.com',
  password: 'pw',
);

// Other providers
await auth.tracedSignInAnonymously();
await auth.tracedSignInWithCustomToken(token);
await auth.tracedSignInWithCredential(googleCred);

// Sign out + password reset
await auth.tracedSignOut();
await auth.tracedSendPasswordResetEmail(email: 'alice@example.com');
```

## Span shape

| Span name | `auth.operation` | `auth.provider` |
|---|---|---|
| `firebase_auth sign_in` | `sign_in` | `password` / `anonymous` / `custom_token` / `<credential.providerId>` |
| `firebase_auth create_user` | `create_user` | `password` |
| `firebase_auth sign_out` | `sign_out` | — |
| `firebase_auth send_password_reset` | `send_password_reset` | `password` |

Every span also carries `auth.system=firebase`.

- **Span kind**: `CLIENT`.
- **`enduser.id`**: the successful user's UID is attached on
  sign-in / create-user spans. Pass `recordUserId: false` to skip
  it if your environment treats UIDs as PII.
- **Span status**: `Error` on `FirebaseAuthException` or any other
  thrown error. For `FirebaseAuthException`, `error.type` is set
  to the exception's `code` (e.g. `wrong-password`,
  `user-not-found`) — much more useful than the generic class
  name for alerting and dashboards.
- Spans inherit the surrounding active span as parent, so auth
  calls inside `Tracer.startActiveSpan` nest naturally.

## Self-recursion guard

```dart
await runWithoutFirebaseAuthInstrumentationAsync(() async {
  await auth.tracedSignInAnonymously();
});
```

Inside the helper's zone the `traced*` methods become transparent
passthroughs — the underlying Firebase call still runs, but no
span is opened. Safe to nest. Sync variant:
`runWithoutFirebaseAuthInstrumentation`.

## Caveats

- Phone-auth (`signInWithPhoneNumber` + `verifyPhoneNumber`) and
  the multi-step popup / provider flows aren't yet wrapped — they
  span multiple async steps, and a one-shot wrapper would be
  misleading. Open an issue if you want them; the current
  shipping surface covers ~95% of typical app auth flows.
- The wrapper calls `OTel.tracerProvider().getTracer(...)` on each
  invocation — `OTel.initialize()` must have run first.
- `enduser.id` carries the UID, which may be PII in some legal
  contexts. See the `recordUserId` parameter above.

## License

Apache 2.0 — see `LICENSE`.
