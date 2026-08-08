# otel_firebase_auth example

```dart
// example/lib/main.dart

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:otel_firebase_auth/otel_firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Bring up Firebase and OTel before runApp so trace context is
  //    already flowing when the first auth call happens.
  await Firebase.initializeApp();
  await OTel.initialize(
    serviceName: 'firebase-auth-demo',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: SignInPage());
  }
}

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  Future<void> _signIn() async {
    final auth = FirebaseAuth.instance;
    try {
      // ✨ Span: `firebase_auth sign_in`
      //    auth.system=firebase, auth.operation=sign_in,
      //    auth.provider=password, enduser.id=<uid on success>
      final cred = await auth.tracedSignInWithEmailAndPassword(
        email: 'alice@example.com',
        password: 'correct horse battery staple',
      );
      debugPrint('signed in as ${cred.user?.uid}');
    } on FirebaseAuthException {
      // The span already carries status=Error and
      // error.type=<code> (e.g. `wrong-password`).
      rethrow;
    }
  }

  Future<void> _anonymous() async {
    // ✨ Span: `firebase_auth sign_in` with auth.provider=anonymous.
    //    UIDs treated as PII? Opt out per call:
    await FirebaseAuth.instance.tracedSignInAnonymously(
      recordUserId: false,
    );
  }

  Future<void> _signOut() async {
    // ✨ Span: `firebase_auth sign_out`
    await FirebaseAuth.instance.tracedSignOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(onPressed: _signIn, child: const Text('Sign in')),
            ElevatedButton(
              onPressed: _anonymous,
              child: const Text('Guest'),
            ),
            ElevatedButton(onPressed: _signOut, child: const Text('Sign out')),
          ],
        ),
      ),
    );
  }
}
```

Every `traced*` call opens a `CLIENT` span named `firebase_auth <op>`
with `auth.system=firebase`, `auth.operation`, and (when known)
`auth.provider`. On successful sign-in the user's UID is attached as
`enduser.id` — pass `recordUserId: false` to skip that.

To make the wrapped calls invisible to tracing (e.g. inside your own
instrumentation code), scope them with the suppression helper:

```dart
await runWithoutFirebaseAuthInstrumentationAsync(() async {
  await FirebaseAuth.instance.tracedSignInAnonymously();
});
// no span emitted; the Firebase call still ran
```
