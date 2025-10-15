import 'dart:math';

class Sudoku {
  late List<List<int>> _board;
  late List<List<int>> _solution;

  List<List<int>> get board => _board;
  List<List<int>> get solution => _solution;

  Sudoku() {
    _board = List.generate(9, (_) => List.generate(9, (_) => 0));
    _solution = List.generate(9, (_) => List.generate(9, (_) => 0));
  }

  void updateCell(int row, int col, int value) {
    if (row >= 0 && row < 9 && col >= 0 && col < 9 && value >= 0 && value <= 9) {
      _board[row][col] = value;
    }
  }

  void generateBoard({int difficulty = 55}) {
    _board = List.generate(9, (_) => List.generate(9, (_) => 0));

    _fillDiagonal();
    _solve(_board);

    for (int i = 0; i < 9; i++) {
      _solution[i] = List.from(_board[i]);
    }

    Random rand = Random();
    int count = difficulty;
    while (count > 0) {
      int row = rand.nextInt(9);
      int col = rand.nextInt(9);
      if (_board[row][col] != 0) {
        _board[row][col] = 0;
        count--;
      }
    }
  }

  bool _solve(List<List<int>> currentBoard) {
    List<int>? emptySpot = _findEmpty(currentBoard);
    if (emptySpot == null) {
      return true;
    }

    int row = emptySpot[0];
    int col = emptySpot[1];

    for (int num = 1; num <= 9; num++) {
      if (_isValid(currentBoard, col, row, num)) {
        currentBoard[row][col] = num;
        if (_solve(currentBoard)) {
          return true;
        }
        currentBoard[row][col] = 0; // Backtrack
      }
    }
    return false;
  }

  List<int>? _findEmpty(List<List<int>> currentBoard) {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (currentBoard[i][j] == 0) {
          return [i, j];
        }
      }
    }
    return null;
  }

  bool _isValid(List<List<int>> currentBoard, int col, int row, int val) {
    for (int i = 0; i < 9; i++) {
      if (currentBoard[i][col] == val) return false;
    }
    for (int j = 0; j < 9; j++) {
      if (currentBoard[row][j] == val) return false;
    }
    int startRow = (row ~/ 3) * 3;
    int startCol = (col ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (currentBoard[startRow + i][startCol + j] == val) return false;
      }
    }
    return true;
  }

  void _fillDiagonal() {
    for (int i = 0; i < 9; i = i + 3) {
      _fillBox(i, i);
    }
  }

  void _fillBox(int row, int col) {
    Random rand = Random();
    int num;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        do {
          num = rand.nextInt(9) + 1;
        } while (!_isNotInBox(row, col, num));
        _board[row + i][col + j] = num;
      }
    }
  }

  bool _isNotInBox(int startRow, int startCol, int num) {
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (_board[startRow + i][startCol + j] == num) {
          return false;
        }
      }
    }
    return true;
  }
}