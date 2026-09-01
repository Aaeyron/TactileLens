abstract final class DocumentReadingOrder {
  static const double _minimumColumnSeparationRatio = 0.20;

  static const double _minimumGutterRatio = 0.025;

  static const double _fullWidthRatio = 0.72;

  static List<T> sort<T>({
    required Iterable<T> blocks,
    required List<double> Function(T block) boundingBoxOf,
    double pageWidth = 0,
  }) {
    final List<T> source = blocks.toList(growable: false);

    if (source.length < 2) {
      return source;
    }

    final List<_PositionedBlock<T>> positioned = <_PositionedBlock<T>>[];

    final List<T> unpositioned = <T>[];

    for (int index = 0; index < source.length; index++) {
      final T block = source[index];
      final List<double> boundingBox = boundingBoxOf(block);

      final _BlockBounds? bounds = _BlockBounds.tryParse(boundingBox);

      if (bounds == null) {
        unpositioned.add(block);
        continue;
      }

      positioned.add(
        _PositionedBlock<T>(value: block, originalIndex: index, bounds: bounds),
      );
    }

    if (positioned.length < 2) {
      return source;
    }

    final double resolvedPageWidth = pageWidth > 0
        ? pageWidth
        : positioned
              .map((_PositionedBlock<T> block) => block.bounds.right)
              .reduce(
                (double current, double next) =>
                    current > next ? current : next,
              );

    if (resolvedPageWidth <= 0) {
      return source;
    }

    final List<_PositionedBlock<T>> columnCandidates = positioned
        .where(
          (_PositionedBlock<T> block) =>
              block.bounds.width / resolvedPageWidth < _fullWidthRatio,
        )
        .toList(growable: false);

    final _ColumnSplit<T>? split = _detectTwoColumns(
      columnCandidates,
      resolvedPageWidth,
    );

    final List<T> ordered;

    if (split == null) {
      final List<_PositionedBlock<T>> sorted = List<_PositionedBlock<T>>.from(
        positioned,
      )..sort(_compareTopThenLeft);

      ordered = sorted.map((_PositionedBlock<T> block) => block.value).toList();
    } else {
      ordered = _sortTwoColumnPage(
        positioned: positioned,
        split: split,
        pageWidth: resolvedPageWidth,
      );
    }

    ordered.addAll(unpositioned);

    return List<T>.unmodifiable(ordered);
  }

  static _ColumnSplit<T>? _detectTwoColumns<T>(
    List<_PositionedBlock<T>> candidates,
    double pageWidth,
  ) {
    if (candidates.length < 2) {
      return null;
    }

    double leftCenter = candidates
        .map((_PositionedBlock<T> block) => block.bounds.centerX)
        .reduce(
          (double current, double next) => current < next ? current : next,
        );

    double rightCenter = candidates
        .map((_PositionedBlock<T> block) => block.bounds.centerX)
        .reduce(
          (double current, double next) => current > next ? current : next,
        );

    if (rightCenter - leftCenter < pageWidth * _minimumColumnSeparationRatio) {
      return null;
    }

    List<_PositionedBlock<T>> left = <_PositionedBlock<T>>[];

    List<_PositionedBlock<T>> right = <_PositionedBlock<T>>[];

    for (int iteration = 0; iteration < 8; iteration++) {
      left = <_PositionedBlock<T>>[];
      right = <_PositionedBlock<T>>[];

      for (final _PositionedBlock<T> block in candidates) {
        final double leftDistance = (block.bounds.centerX - leftCenter).abs();

        final double rightDistance = (block.bounds.centerX - rightCenter).abs();

        if (leftDistance <= rightDistance) {
          left.add(block);
        } else {
          right.add(block);
        }
      }

      if (left.isEmpty || right.isEmpty) {
        return null;
      }

      leftCenter = _averageCenter(left);
      rightCenter = _averageCenter(right);
    }

    if (leftCenter > rightCenter) {
      final List<_PositionedBlock<T>> temporary = left;

      left = right;
      right = temporary;

      final double temporaryCenter = leftCenter;

      leftCenter = rightCenter;
      rightCenter = temporaryCenter;
    }

    final double leftMaximumRight = left
        .map((_PositionedBlock<T> block) => block.bounds.right)
        .reduce(
          (double current, double next) => current > next ? current : next,
        );

    final double rightMinimumLeft = right
        .map((_PositionedBlock<T> block) => block.bounds.left)
        .reduce(
          (double current, double next) => current < next ? current : next,
        );

    final double gutter = rightMinimumLeft - leftMaximumRight;

    final double centerSeparation = rightCenter - leftCenter;

    if (centerSeparation < pageWidth * _minimumColumnSeparationRatio ||
        gutter < pageWidth * _minimumGutterRatio) {
      return null;
    }

    final double leftTop = _minimumTop(left);
    final double leftBottom = _maximumBottom(left);

    final double rightTop = _minimumTop(right);

    final double rightBottom = _maximumBottom(right);

    final double overlapTop = leftTop > rightTop ? leftTop : rightTop;

    final double overlapBottom = leftBottom < rightBottom
        ? leftBottom
        : rightBottom;

    if (overlapBottom <= overlapTop) {
      return null;
    }

    return _ColumnSplit<T>(
      leftCenter: leftCenter,
      rightCenter: rightCenter,
      gutterLeft: leftMaximumRight,
      gutterRight: rightMinimumLeft,
    );
  }

  static List<T> _sortTwoColumnPage<T>({
    required List<_PositionedBlock<T>> positioned,
    required _ColumnSplit<T> split,
    required double pageWidth,
  }) {
    final List<_PositionedBlock<T>> fullWidthBlocks = <_PositionedBlock<T>>[];

    final List<_PositionedBlock<T>> columnBlocks = <_PositionedBlock<T>>[];

    for (final _PositionedBlock<T> block in positioned) {
      final bool occupiesFullWidth =
          block.bounds.width / pageWidth >= _fullWidthRatio ||
          (block.bounds.left <= split.gutterLeft &&
              block.bounds.right >= split.gutterRight);

      if (occupiesFullWidth) {
        fullWidthBlocks.add(block);
      } else {
        columnBlocks.add(block);
      }
    }

    fullWidthBlocks.sort(_compareTopThenLeft);

    final List<_PositionedBlock<T>> ordered = <_PositionedBlock<T>>[];

    final Set<int> emittedIndexes = <int>{};

    for (final _PositionedBlock<T> anchor in fullWidthBlocks) {
      final List<_PositionedBlock<T>> preceding = columnBlocks
          .where(
            (_PositionedBlock<T> block) =>
                !emittedIndexes.contains(block.originalIndex) &&
                block.bounds.centerY < anchor.bounds.centerY,
          )
          .toList();

      _appendColumnMajor(ordered, preceding, split, emittedIndexes);

      ordered.add(anchor);
      emittedIndexes.add(anchor.originalIndex);
    }

    final List<_PositionedBlock<T>> remaining = columnBlocks
        .where(
          (_PositionedBlock<T> block) =>
              !emittedIndexes.contains(block.originalIndex),
        )
        .toList();

    _appendColumnMajor(ordered, remaining, split, emittedIndexes);

    return ordered
        .map((_PositionedBlock<T> block) => block.value)
        .toList(growable: true);
  }

  static void _appendColumnMajor<T>(
    List<_PositionedBlock<T>> destination,
    List<_PositionedBlock<T>> blocks,
    _ColumnSplit<T> split,
    Set<int> emittedIndexes,
  ) {
    final List<_PositionedBlock<T>> left = <_PositionedBlock<T>>[];

    final List<_PositionedBlock<T>> right = <_PositionedBlock<T>>[];

    for (final _PositionedBlock<T> block in blocks) {
      final double leftDistance = (block.bounds.centerX - split.leftCenter)
          .abs();

      final double rightDistance = (block.bounds.centerX - split.rightCenter)
          .abs();

      if (leftDistance <= rightDistance) {
        left.add(block);
      } else {
        right.add(block);
      }
    }

    left.sort(_compareTopThenLeft);
    right.sort(_compareTopThenLeft);

    for (final _PositionedBlock<T> block in <_PositionedBlock<T>>[
      ...left,
      ...right,
    ]) {
      if (emittedIndexes.add(block.originalIndex)) {
        destination.add(block);
      }
    }
  }

  static double _averageCenter<T>(List<_PositionedBlock<T>> blocks) {
    final double total = blocks.fold<double>(
      0,
      (double sum, _PositionedBlock<T> block) => sum + block.bounds.centerX,
    );

    return total / blocks.length;
  }

  static double _minimumTop<T>(List<_PositionedBlock<T>> blocks) {
    return blocks
        .map((_PositionedBlock<T> block) => block.bounds.top)
        .reduce(
          (double current, double next) => current < next ? current : next,
        );
  }

  static double _maximumBottom<T>(List<_PositionedBlock<T>> blocks) {
    return blocks
        .map((_PositionedBlock<T> block) => block.bounds.bottom)
        .reduce(
          (double current, double next) => current > next ? current : next,
        );
  }

  static int _compareTopThenLeft<T>(
    _PositionedBlock<T> first,
    _PositionedBlock<T> second,
  ) {
    final int verticalComparison = first.bounds.top.compareTo(
      second.bounds.top,
    );

    if (verticalComparison != 0) {
      return verticalComparison;
    }

    final int horizontalComparison = first.bounds.left.compareTo(
      second.bounds.left,
    );

    if (horizontalComparison != 0) {
      return horizontalComparison;
    }

    return first.originalIndex.compareTo(second.originalIndex);
  }
}

class _ColumnSplit<T> {
  const _ColumnSplit({
    required this.leftCenter,
    required this.rightCenter,
    required this.gutterLeft,
    required this.gutterRight,
  });

  final double leftCenter;
  final double rightCenter;
  final double gutterLeft;
  final double gutterRight;
}

class _PositionedBlock<T> {
  const _PositionedBlock({
    required this.value,
    required this.originalIndex,
    required this.bounds,
  });

  final T value;
  final int originalIndex;
  final _BlockBounds bounds;
}

class _BlockBounds {
  const _BlockBounds({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;

  static _BlockBounds? tryParse(List<double> values) {
    if (values.length < 4) {
      return null;
    }

    final double firstX = values[0];
    final double firstY = values[1];
    final double secondX = values[2];
    final double secondY = values[3];

    final double left = firstX < secondX ? firstX : secondX;

    final double right = firstX > secondX ? firstX : secondX;

    final double top = firstY < secondY ? firstY : secondY;

    final double bottom = firstY > secondY ? firstY : secondY;

    if (right <= left || bottom <= top) {
      return null;
    }

    return _BlockBounds(left: left, top: top, right: right, bottom: bottom);
  }
}
