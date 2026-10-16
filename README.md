<!-- dartastic-header:start -->
# OpenTelemetry instrumentation for `firebase_auth`

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![OpenTelemetry Specification](https://img.shields.io/badge/OpenTelemetry-Specification-blueviolet)](https://opentelemetry.io/docs/specs/otel/)

`otel_firebase_auth` is an [OpenTelemetry](https://opentelemetry.io/) instrumentation for `firebase_auth` that
easily adds standard observability to applications that use `firebase_auth`.  This package depends on 
[dartastic_opentelemetry_api](https://pub.dev/packages/dartastic_opentelemetry_api).

This package can be used with any OTel backend because it's compliant with the OpenTelemetry Specification.

This package supports Android, iOS, macOS, Web and Windows, for versions of `firebase_auth` that support those platforms. It is WASM-ready.

This Apache-2.0 package is professionally maintained and supported with 💙 by Michael Bushe,
Dart and Flutter Maintainer at OpenTelemetry and the creator of [dartastic_opentelemetry](https://pub.dev/packages/dartastic_opentelemetry)
and [dartastic_opentelemetry_api](https://pub.dev/packages/dartastic_opentelemetry_api). This package is professionally supported by
[Dartastic.io](https://dartastic.io).

---
## Dartastic.io: AI Code Healing and Real User Monitoring for Flutter

**See what your users experience. Find problems with Flutter apps in production. Fix them with AI.**

[Dartastic.io](https://dartastic.io) brings AI code healing, real user monitoring, and OpenTelemetry observability together in one platform built for Dart and Flutter. (Patents pending)

![Dartastic AI answering "Why did crashes jump after the last release?" over a Flutter App Health dashboard](https://dartastic.io/img/pub-dev/HomePageCrashesQuestion.png)

### Dartastic AI — From Production Problems to Code Fixes

Dartastic AI analyzes production telemetry alongside your application source code to diagnose problems and propose fixes.

- **Investigate production issues** using crashes, errors, traces, metrics, and real user telemetry.
- **Find the offending code** by connecting observed problems with your application's source in Dartastic Pub or your source code repos.
- **Generate code patches** that address the underlying problems.
- **Create actionable issues** in your issue tracker, complete with findings and the proposed code patch.

### Dartastic RUM — See What Your Users See

Understand how people actually experience your Flutter application.

- **Replay user sessions** in the Dartastic Observatory session player.
- **Choose your replay fidelity**, from privacy-preserving widget outlines to pixel-level reproductions of the user experience.
- **Investigate real user problems** using session replay and production observability data.

![Dartastic RUM Session Replay](https://dartastic.io/img/pub-dev/session-replay.png)

### Dartastic Observatory — Observability Built for Flutter

A complete observability backend where Flutter and Dart are first-class citizens.

- **Flutter-specific dashboards** for application performance, health, and reliability.
- **Alerts and notifications** through email, Slack, and PagerDuty.
- **Dartastic Cloud Observatory** — Start with a 30-day free trial on isolated, shared infrastructure, as low as $39/mo.
- **Dartastic Hosted Observatory** — Run the observability stack in a private managed environment, sized from Mini to Enterprise XL.
- **Dartastic Self-Hosted Observatory** — The whole platform inside your own network. Your keys, your cluster, with nothing leaving your perimeter.

### Dartastic Native OTel Runtime — Native OpenTelemetry Performance

Collect production telemetry without burdening Flutter's main isolate.

- **Native OpenTelemetry runtime** that moves telemetry processing off the main isolate.
- **Native crash reporting** for problems that Dart can't catch.
- **Widget performance diagnostics** to identify janky widgets.
- **On-device PII filtering** before sensitive data leaves your application.
- **Source-level error diagnostics** powered by the Dartastic Symbolizer API.
- **Platform-native metrics** for iOS, Android, and Linux, including iOS MetricKit and Android Vitals.
- **OpenTelemetry compatibility** — Send telemetry to Dartastic Observatory or any OpenTelemetry platform.

### Dartastic Labs — OpenTelemetry Integrations

Instrument more of your application without writing everything yourself.

- **650+ open-source integrations** for Dart and Flutter libraries and services, including Dio, Shelf, Logger, Anthropic, AWS, Azure, and Stripe. Look for otel_* on pub.dev.

### More Dartastic Tools

**[Dartastic Pub](https://dartastic.io/pub)**

A private Dart package registry for sharing packages and plugins with your team, partners, and customers.

**[Dartastic Symbolizer](https://dartastic.io/symbolizer)**

Turn production errors into lines of source code through a web API, while keeping your source code artifacts private.

### Professional Support and Training

Dartastic.io offers commercial support for the open-source `dartastic_opentelemetry` and `dartastic_opentelemetry_api` packages and the complete Dartastic product suite.

- **Professional support** with available around-the-clock coverage and response times under four hours on qualifying plans.
- **OpenTelemetry training** for teams instrumenting Dart, Flutter, mobile, and web applications.

### Open Standards. No Mandatory Backend.

The Dartastic OpenTelemetry API and SDK are open source and standards-based. You can use them independently of Dartastic's commercial services and send telemetry to any compatible OpenTelemetry backend.

Dartastic's commercial products add native performance, advanced diagnostics, session replay, AI-assisted remediation, and managed observability services.

**[Explore Dartastic.io](https://dartastic.io)**

---
<!-- dartastic-header:end -->

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
