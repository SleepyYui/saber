import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:saber/components/canvas/_stroke.dart';
import 'package:sbn/has_size.dart';

void main() {
  group('Stroke.convertToLine', () {
    /// Creates a pencil-like stroke (with taper enabled) that looks like a
    /// straight line so [Stroke.isStraightLine] returns true.
    Stroke _makeStraightPencilStroke() {
      final penStart = StrokeEndOptions.start(
        taperEnabled: true,
        customTaper: 1,
      );
      final penEnd = StrokeEndOptions.end(
        taperEnabled: true,
        customTaper: 1,
      );
      final penOptions = StrokeOptions(
        size: 5,
        streamline: 0.1,
        start: penStart,
        end: penEnd,
      );

      // Shallow-copy like Pen.onDragStart does.
      final strokeOptions = penOptions.copyWith(isComplete: false);

      final stroke = Stroke(
        color: Stroke.defaultColor,
        pressureEnabled: Stroke.defaultPressureEnabled,
        options: strokeOptions,
        pageIndex: 0,
        page: const HasSize(Size(1000, 1400)),
        toolId: .pencil,
      );

      // Add a few collinear points so isStraightLine returns true.
      for (int i = 0; i <= 20; i++) {
        stroke.addPoint(Offset(i * 50.0, 0));
      }
      stroke.options.isComplete = true;

      return stroke;
    }

    test('convertToLine does not mutate the pen\'s shared StrokeEndOptions',
        () {
      final penStart = StrokeEndOptions.start(
        taperEnabled: true,
        customTaper: 1,
      );
      final penEnd = StrokeEndOptions.end(
        taperEnabled: true,
        customTaper: 1,
      );
      final penOptions = StrokeOptions(
        size: 5,
        streamline: 0.1,
        start: penStart,
        end: penEnd,
      );

      // Shallow-copy like Pen.onDragStart does.
      final strokeOptions = penOptions.copyWith(isComplete: false);

      final stroke = Stroke(
        color: Stroke.defaultColor,
        pressureEnabled: Stroke.defaultPressureEnabled,
        options: strokeOptions,
        pageIndex: 0,
        page: const HasSize(Size(1000, 1400)),
        toolId: .pencil,
      );

      for (int i = 0; i <= 20; i++) {
        stroke.addPoint(Offset(i * 50.0, 0));
      }
      stroke.options.isComplete = true;

      // Confirm the stroke shares the pen's start/end objects before the call.
      expect(identical(strokeOptions.start, penStart), isTrue,
          reason: 'StrokeOptions.copyWith should shallow-copy start/end');

      stroke.convertToLine();

      // After convertToLine the pen's original start/end must be untouched.
      expect(penStart.taperEnabled, isTrue,
          reason:
              'convertToLine must not mutate the pen\'s shared start options');
      expect(penEnd.taperEnabled, isTrue,
          reason:
              'convertToLine must not mutate the pen\'s shared end options');
      expect(penStart.customTaper, equals(1),
          reason: 'pen customTaper must remain unchanged');

      // The stroke itself should have taper disabled after the conversion.
      expect(stroke.options.start.taperEnabled, isFalse);
      expect(stroke.options.end.taperEnabled, isFalse);
    });

    test('isStraightLine returns true for a horizontal stroke', () {
      final stroke = _makeStraightPencilStroke();
      expect(stroke.isStraightLine(), isTrue);
    });
  });
}
