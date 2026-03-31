/// 🤖 Generated wholely or partially with Claude Sonnet 4.5
library;

import 'dart:ui';

import 'package:logging/logging.dart';

abstract class PencilShader {
  static final _log = Logger('PencilShader');

  static FragmentProgram? _program;

  /// Whether the pencil shader is available on this device.
  static bool get isAvailable => _program != null;

  /// Initialises the pencil shader.
  ///
  /// If the shader fails to load (e.g. on devices with unsupported GPU
  /// drivers), the error is logged and [isAvailable] will be false.
  /// The app will fall back to the plain pencil rendering in that case.
  static Future<void> init() async {
    try {
      _program = await FragmentProgram.fromAsset('shaders/pencil.frag');
    } catch (e, st) {
      _log.warning(
        'Failed to load pencil shader; falling back to plain rendering.',
        e,
        st,
      );
    }
  }

  /// Creates a new [FragmentShader] from the pencil shader program.
  ///
  /// Returns null if the shader is not available (see [isAvailable]).
  static FragmentShader? create() {
    return _program?.fragmentShader();
  }
}
