/// Annotation class for marking state classes.
class PureState {
  /// Creates a [PureState] annotation.
  const PureState();
}

/// Annotation for marking actions that should be processed by a code generator.
class PureActionDef {
  /// Creates a [PureActionDef] annotation.
  const PureActionDef();
}

/// Annotation for marking fields that should be included in code generation.
class PureField {
  /// Creates a [PureField] annotation.
  const PureField();
}
