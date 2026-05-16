// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:otel_firebase_auth/otel_firebase_auth.dart';

class _MemorySpanExporter implements SpanExporter {
  final List<Span> spans = [];
  bool _shutdown = false;

  @override
  Future<void> export(List<Span> s) async {
    if (_shutdown) return;
    spans.addAll(s);
  }

  @override
  Future<void> forceFlush() async {}

  @override
  Future<void> shutdown() async {
    _shutdown = true;
  }
}

Map<String, Object> _attrs(Span span) =>
    {for (final a in span.attributes.toList()) a.key: a.value};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OTel FirebaseAuth extensions', () {
    late _MemorySpanExporter exporter;

    setUp(() async {
      await OTel.reset();
      exporter = _MemorySpanExporter();
      await OTel.initialize(
        serviceName: 'firebase-auth-otel-test',
        detectPlatformResources: false,
        spanProcessor: SimpleSpanProcessor(exporter),
      );
    });

    tearDown(() async {
      await OTel.shutdown();
      await OTel.reset();
    });

    test('tracedSignInWithEmailAndPassword emits CLIENT auth.* span + uid',
        () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'user-123', email: 'alice@example.com'),
      );

      final cred = await auth.tracedSignInWithEmailAndPassword(
        email: 'alice@example.com',
        password: 'pw',
      );
      expect(cred.user?.uid, equals('user-123'));

      final span = exporter.spans.single;
      expect(span.name, equals('firebase_auth sign_in'));
      expect(span.kind, equals(SpanKind.client));
      final attrs = _attrs(span);
      expect(attrs['auth.system'], equals('firebase'));
      expect(attrs['auth.operation'], equals('sign_in'));
      expect(attrs['auth.provider'], equals('password'));
      expect(attrs['enduser.id'], equals('user-123'));
      expect(span.status, isNot(equals(SpanStatusCode.Error)));
    });

    test('recordUserId: false omits enduser.id', () async {
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'user-123'));
      await auth.tracedSignInWithEmailAndPassword(
        email: 'x@x.com',
        password: 'pw',
        recordUserId: false,
      );
      final span = exporter.spans.single;
      expect(_attrs(span).containsKey('enduser.id'), isFalse);
    });

    test('tracedSignInAnonymously sets auth.provider=anonymous', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'anon-1', isAnonymous: true),
      );
      await auth.tracedSignInAnonymously();
      final span = exporter.spans.single;
      expect(_attrs(span)['auth.provider'], equals('anonymous'));
    });

    test('tracedSignOut emits a sign_out span', () async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'u'),
      );
      await auth.tracedSignOut();
      final span = exporter.spans.firstWhere(
        (s) => s.name == 'firebase_auth sign_out',
      );
      expect(_attrs(span)['auth.operation'], equals('sign_out'));
    });

    test('FirebaseAuthException flips span status to Error with code',
        () async {
      final auth = MockFirebaseAuth();
      whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(
            code: 'wrong-password',
            message: 'The password is invalid.',
          ));

      await expectLater(
        auth.tracedSignInWithEmailAndPassword(
          email: 'x@x.com',
          password: 'bad',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );

      final span = exporter.spans.single;
      expect(span.status, equals(SpanStatusCode.Error));
      final attrs = _attrs(span);
      expect(attrs['error.type'], equals('wrong-password'));
      final events = span.spanEvents ?? [];
      expect(events.any((e) => e.name == 'exception'), isTrue);
    });

    test('runWithoutFirebaseAuthInstrumentationAsync bypasses spans', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u', isAnonymous: true),
      );
      await runWithoutFirebaseAuthInstrumentationAsync(() async {
        await auth.tracedSignInAnonymously();
      });
      expect(exporter.spans, isEmpty);
    });
  });
}
