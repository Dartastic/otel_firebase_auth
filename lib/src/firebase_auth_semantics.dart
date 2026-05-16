// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

/// Firebase Auth-specific attribute keys.
///
/// `auth.system` and `auth.operation` aren't yet in the OTel
/// semconv as stable keys for identity operations, but are a
/// natural extension of the `enduser.*` namespace already there
/// (`enduser.id`, `enduser.role`, `enduser.scope`). Held here
/// until upstream picks them up.
enum FirebaseAuthSemantics implements OTelSemantic {
  /// `auth.system` — the identity system (always `firebase` here).
  system('auth.system'),

  /// `auth.operation` — `sign_in`, `sign_out`, `create_user`, etc.
  operation('auth.operation'),

  /// `auth.provider` — `password`, `anonymous`, `custom_token`,
  /// `google.com`, `apple.com`, etc. Mirrors Firebase's own
  /// `providerId`.
  provider('auth.provider');

  @override
  final String key;

  @override
  String toString() => key;

  const FirebaseAuthSemantics(this.key);
}
