part of pluto_grid;

class PlutoStateManager extends ChangeNotifier {
  List<PlutoColumn> _columns;

  List<PlutoColumn> get columns => _columns;

  List<PlutoRow> _rows;

  List<PlutoRow> get rows => _rows;

  FocusNode _gridFocusNode;

  FocusNode get gridFocusNode => _gridFocusNode;

  PlutoScrollController _scroll;

  PlutoScrollController get scroll => _scroll;

  PlutoStyle _style;

  PlutoStyle get style => _style;

  PlutoStateManager({
    @required List<PlutoColumn> columns,
    @required List<PlutoRow> rows,
    @required FocusNode gridFocusNode,
    @required PlutoScrollController scroll,
    PlutoStyle style,
  })  : this._columns = columns,
        this._rows = rows,
        this._gridFocusNode = gridFocusNode,
        this._scroll = scroll,
        this._style = style ?? PlutoStyle();

  /// 전체 컬럼의 인덱스 리스트
  List<int> get columnIndexes => _columns.asMap().keys.toList();

  /// fixed 컬럼이 있는 경우 넓이가 좁을 때 fixed 컬럼의 순서를 유지하는 전체 컬럼의 인덱스 리스트
  List<int> get columnIndexesForShowFixed {
    // todo : 우측 고정
    return [...leftFixedColumnIndexes, ...bodyColumnIndexes];
  }

  /// 전체 컬럼의 넓이
  double get columnsWidth {
    return _columns.fold(0, (double value, element) => value + element.width);
  }

  /// 왼쪽 고정 컬럼
  List<PlutoColumn> get leftFixedColumns {
    return _columns.where((e) => e.fixed.isLeft).toList();
  }

  /// 왼쪽 고정 컬럼의 인덱스 리스트
  List<int> get leftFixedColumnIndexes {
    return _columns.fold<List<int>>([], (List<int> previousValue, element) {
      if (element.fixed.isLeft) {
        return [...previousValue, columns.indexOf(element)];
      }
      return previousValue;
    }).toList();
  }

  /// 왼쪽 고정 컬럼의 넓이
  double get leftFixedColumnsWidth {
    return leftFixedColumns.fold(
        0, (double value, element) => value + element.width);
  }

  /// body 컬럼
  List<PlutoColumn> get bodyColumns {
    return _columns.where((e) => e.fixed.isNone).toList();
  }

  /// body 컬럼 인덱스 리스트
  List<int> get bodyColumnIndexes {
    return bodyColumns.fold<List<int>>([], (List<int> previousValue, element) {
      if (element.fixed.isNone) {
        return [...previousValue, columns.indexOf(element)];
      }
      return previousValue;
    }).toList();
  }

  /// body 컬럼의 넓이
  double get bodyColumnsWidth {
    return bodyColumns.fold(
        0, (double value, element) => value + element.width);
  }

  /// 화면 사이즈와 고정 컬럼 출력 여부
  PlutoLayout _layout;

  PlutoLayout get layout => _layout;

  /// LayoutBuilder 가 build 될 때 화면 사이즈 정보 갱신
  void setLayout(BoxConstraints size) {
    _layout = PlutoLayout(
      maxWidth: size.maxWidth,
      maxHeight: size.maxHeight,
      showFixedColumn: isShowFixedColumn(size.maxWidth),
    );
  }

  /// 현재 선택 된 셀
  PlutoCell _currentCell;

  PlutoCell get currentCell => _currentCell;

  /// 현재 선택 된 셀을 변경
  void setCurrentCell(PlutoCell cell) {
    if (_currentCell != null && _currentCell._key == cell._key) {
      return;
    }
    _currentCell = cell;
    _isEditing = false;
    notifyListeners();
  }

  /// 현재 셀의 편집 상태
  bool _isEditing = false;

  bool get isEditing => _isEditing;

  /// 현재 셀의 편집 상태를 변경
  void setEditing(bool flag) {
    if (_currentCell == null || _isEditing == flag) {
      return;
    }
    _isEditing = flag;
    notifyListeners();
  }

  /// 현재 셀의 편집 상태를 토글
  void toggleEditing() => setEditing(!(_isEditing == true));

  /// 컬럼의 고정 여부를 토글
  void toggleFixedColumn(GlobalKey columnKey) {
    for (var i = 0; i < _columns.length; i += 1) {
      if (_columns[i]._key == columnKey) {
        _columns[i].fixed = _columns[i].fixed.isFixed
            ? PlutoColumnFixed.None
            : PlutoColumnFixed.Left;
        break;
      }
    }
    notifyListeners();
  }

  /// 전체 컬럼의 인덱스 위치까지의 넓이
  double columnsWidthAtColumnIdx(int columnIdx) {
    double width = 0.0;
    columnIndexes.getRange(0, columnIdx).forEach((idx) {
      width += _columns[idx].width;
    });
    return width;
  }

  /// body 컬럼의 인덱스 까지의 넓이
  double bodyColumnsWidthAtColumnIdx(int columnIdx) {
    double width = 0.0;
    bodyColumnIndexes.getRange(0, columnIdx).forEach((idx) {
      width += columns[idx].width;
    });
    return width;
  }

  /// 고정 컬럼 여부에 따른 컬럼 인덱스 리스트
  List<int> columnIndexesByShowFixed() {
    return _layout.showFixedColumn ? columnIndexesForShowFixed : columnIndexes;
  }

  /// 해당 컬럼 인덱스에서 셀의 인덱스 위치
  PlutoCellPosition cellPositionByCellKey(
      GlobalKey cellKey, List<int> columnIndexes) {
    for (var rowIdx = 0; rowIdx < _rows.length; rowIdx += 1) {
      for (var columnIdx = 0;
          columnIdx < columnIndexes.length;
          columnIdx += 1) {
        final field = _columns[columnIndexes[columnIdx]].field;
        if (_rows[rowIdx].cells[field]._key == cellKey) {
          return PlutoCellPosition(columnIdx: columnIdx, rowIdx: rowIdx);
        }
      }
    }
    throw Exception('CellKey was not found in the list.');
  }

  /// 셀의 위치에서 해당 뱡향으로 이동 가능 한 여부
  bool canNotMoveCell(PlutoCellPosition cellPosition, MoveDirection direction) {
    return !canMoveCell(cellPosition, direction);
  }

  bool canMoveCell(PlutoCellPosition cellPosition, MoveDirection direction) {
    switch (direction) {
      case MoveDirection.Left:
        return cellPosition.columnIdx > 0;
      case MoveDirection.Right:
        return cellPosition.columnIdx <
            _rows[cellPosition.rowIdx].cells.length - 1;
      case MoveDirection.Up:
        return cellPosition.rowIdx > 0;
      case MoveDirection.Down:
        return cellPosition.rowIdx < _rows.length - 1;
    }
    throw Exception('MoveDirection case was not handled.');
  }

  /// 움직이려는 셀의 위치로 스크롤이 이동 할 수 있는지 여부
  bool canHorizontalCellScrollByDirection(
    MoveDirection direction,
    PlutoColumn columnToMove,
  ) {
    // 고정 컬럼이 보여지는 상태에서 이동 할 컬럼이 고정 컬럼인 경우 스크롤 불필요
    return !(_layout.showFixedColumn == true && columnToMove.fixed.isFixed);
  }

  /// 현재 셀에서 해당 방향으로 이동 하려는 셀의 인덱스 위치
  /// columnIndexes : 현재 셀이 위치하고 있는 컬럼(leftFixed, body)
  PlutoCellPosition cellPositionToMove(
    PlutoCellPosition cellPosition,
    MoveDirection direction,
    List<int> columnIndexes,
  ) {
    switch (direction) {
      case MoveDirection.Left:
        return PlutoCellPosition(
          columnIdx: columnIndexes[cellPosition.columnIdx - 1],
          rowIdx: cellPosition.rowIdx,
        );
      case MoveDirection.Right:
        return PlutoCellPosition(
          columnIdx: columnIndexes[cellPosition.columnIdx + 1],
          rowIdx: cellPosition.rowIdx,
        );
      case MoveDirection.Up:
        return PlutoCellPosition(
          columnIdx: columnIndexes[cellPosition.columnIdx],
          rowIdx: cellPosition.rowIdx - 1,
        );
      case MoveDirection.Down:
        return PlutoCellPosition(
          columnIdx: columnIndexes[cellPosition.columnIdx],
          rowIdx: cellPosition.rowIdx + 1,
        );
    }
    throw Exception('MoveDirection case was not handled.');
  }

  /// 현재 셀을 direction 방향의 셀로 변경하고 스크롤을 이동 시킴
  bool moveCurrentCell(MoveDirection direction) {
    if (_currentCell == null) {
      return false;
    }

    if (_isEditing && direction.horizontal) {
      return false;
    }

    final columnIndexes = columnIndexesByShowFixed();
    final cellPosition =
        cellPositionByCellKey(_currentCell._key, columnIndexes);

    if (canNotMoveCell(cellPosition, direction)) {
      return false;
    }

    final toMove = cellPositionToMove(
      cellPosition,
      direction,
      columnIndexes,
    );

    setCurrentCell(_rows[toMove.rowIdx].cells[_columns[toMove.columnIdx].field]);

    if (direction.horizontal) {
      moveScrollByColumn(direction, cellPosition.columnIdx);
    } else if (direction.vertical) {
      moveScrollByRow(direction, cellPosition.rowIdx);
    }
    return true;
  }

  /// offset 으로 direction 뱡향으로 스크롤
  void scrollByDirection(MoveDirection direction, double offset) {
    if (direction.isLeft && offset < _scroll.horizontal.offset ||
        direction.isRight && offset > _scroll.horizontal.offset) {
      _scroll.horizontal.jumpTo(offset);
    } else if (direction.isUp && offset < _scroll.vertical.offset ||
        direction.isDown && offset > _scroll.vertical.offset) {
      _scroll.vertical.jumpTo(offset);
    }
  }

  /// rowIdx 로 스크롤
  void moveScrollByRow(MoveDirection direction, int rowIdx) {
    if (!direction.vertical) {
      return;
    }

    final double offset = direction.isUp
        ? ((rowIdx - 1) * _style.rowHeight)
        : ((rowIdx + 3) * _style.rowHeight) + 6 - (_layout.maxHeight);

    scrollByDirection(direction, offset);
  }

  /// columnIdx 로 스크롤
  void moveScrollByColumn(MoveDirection direction, int columnIdx) {
    if (!direction.horizontal) {
      return;
    }

    final PlutoColumn columnToMove =
        _columns[columnIndexesForShowFixed[columnIdx + direction.offset]];

    if (!canHorizontalCellScrollByDirection(
      direction,
      columnToMove,
    )) {
      return;
    }

    // 우측 이동의 경우 스크롤 위치를 셀의 우측 끝에 맞추기 위해 컬럼을 한칸 더 이동하여 계산.
    if (direction.isRight) columnIdx++;
    // 이동할 스크롤 포지션 계산을 위해 이동 할 컬럼까지의 넓이 합계를 구한다.
    double offset = layout.showFixedColumn == true
        ? bodyColumnsWidthAtColumnIdx(
            columnIdx + direction.offset - leftFixedColumnIndexes.length)
        : columnsWidthAtColumnIdx(columnIdx + direction.offset);

    if (direction.isRight) {
      final double screenOffset = _layout.showFixedColumn == true
          ? _layout.maxWidth - leftFixedColumnsWidth
          : _layout.maxWidth;
      offset -= screenOffset;
      offset += 6;
    }

    scrollByDirection(direction, offset);
  }

  /// 셀이 현재 선택 된 셀인지 여부
  bool isCurrentCell(PlutoCell cell) {
    return _currentCell != null && _currentCell._key == cell._key;
  }

  /// 화면 넓이에서 fixed 컬럼이 보여질지 여부
  bool isShowFixedColumn(double maxWidth) {
    return leftFixedColumns.length > 0 &&
        maxWidth > (leftFixedColumnsWidth + _style.bodyMinWidth);
  }
}

class PlutoScrollController {
  LinkedScrollControllerGroup vertical;
  ScrollController leftFixedRowsVertical;
  ScrollController bodyRowsVertical;

  LinkedScrollControllerGroup horizontal;
  ScrollController bodyHeadersHorizontal;
  ScrollController bodyRowsHorizontal;

  PlutoScrollController({
    this.vertical,
    this.leftFixedRowsVertical,
    this.bodyRowsVertical,
    this.horizontal,
    this.bodyHeadersHorizontal,
    this.bodyRowsHorizontal,
  });
}

class PlutoStyle {
  double bodyMinWidth;
  double rowHeight;

  PlutoStyle({
    this.bodyMinWidth = PlutoDefaultSettings.bodyMinWidth,
    this.rowHeight = PlutoDefaultSettings.rowHeight,
  });
}

class PlutoLayout {
  /// 화면 최대 넓이
  double maxWidth;

  /// 화면 최대 높이
  double maxHeight;

  /// 화면 사이즈에 따른 고정 컬럼 적용 여부
  /// true : 고정 컬럼이 있는 경우 고정 컬럼이 노출
  /// false : 고정 컬럼이 있지만 화면이 좁은 경우 일반 컬럼으로 노출
  bool showFixedColumn;

  PlutoLayout({
    this.maxWidth,
    this.maxHeight,
    this.showFixedColumn,
  });
}

class PlutoCellPosition {
  int columnIdx;
  int rowIdx;

  PlutoCellPosition({
    this.columnIdx,
    this.rowIdx,
  });
}