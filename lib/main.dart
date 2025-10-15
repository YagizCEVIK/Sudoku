import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'sudoku.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    title: "NoAdSudoku",
    size: Size(800, 750),
    center: true,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NoAdSudoku',
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SudokuScreen(),
    );
  }
}

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  final Sudoku sudoku = Sudoku();
  late List<List<int>> _initialBoard;

  bool _isGameStarted = false;
  int _mistakeCount = 0;
  bool _isGameOver = false;
  bool _isGameWon = false;
  final int _mistakeLimit = 5;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      sudoku.generateBoard(difficulty: 40);
      _initialBoard = sudoku.board.map<List<int>>((row) {
        return row.map<int>((item) => item).toList();
      }).toList();
      _mistakeCount = 0;
      _isGameOver = false;
      _isGameWon = false;
    });
  }

  void _startGame() {
    setState(() {
      _isGameStarted = true;
    });
  }

  bool _isBoardComplete() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (sudoku.board[r][c] == 0 || sudoku.board[r][c] != sudoku.solution[r][c]) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _resetGame();
                _isGameStarted = false;
              });
            },
          ),
        ],
      ),
      body: _isGameStarted ? _buildGameBoard() : _buildStartScreen(),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Game'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          textStyle: const TextStyle(fontSize: 20),
        ),
        onPressed: _startGame,
      ),
    );
  }

  Widget _buildGameBoard() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Flexible(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2.0),
                    ),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 9,
                      ),
                      itemCount: 81,
                      itemBuilder: (context, index) {
                        final row = index ~/ 9;
                        final col = index % 9;
                        final number = _isGameOver ? sudoku.solution[row][col] : sudoku.board[row][col];
                        final isInitial = _initialBoard[row][col] != 0;
                        final isWrong = sudoku.board[row][col] != 0 && sudoku.board[row][col] != sudoku.solution[row][col];

                        return DragTarget<int>(
                          builder: (context, candidateData, rejectedData) {
                            return Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: candidateData.isNotEmpty ? Colors.lightGreen.shade200 : Colors.white,
                                border: Border(
                                  top: BorderSide(width: (row % 3 == 0) ? 1.5 : 0.5),
                                  left: BorderSide(width: (col % 3 == 0) ? 1.5 : 0.5),
                                  bottom: BorderSide(width: (row == 8) ? 1.5 : 0.5),
                                  right: BorderSide(width: (col == 8) ? 1.5 : 0.5),
                                ),
                              ),
                              child: Text(
                                number == 0 ? '' : number.toString(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: isInitial ? FontWeight.bold : FontWeight.normal,
                                  color: _isGameOver
                                      ? (isInitial ? Colors.black : Colors.green.shade800)
                                      : (isWrong ? Colors.red.shade700 : Colors.black),
                                ),
                              ),
                            );
                          },
                          onWillAcceptWithDetails: (details) {
                            return !_isGameOver && !_isGameWon && !isInitial;
                          },
                          onAcceptWithDetails: (details) {
                            final droppedNumber = details.data;
                            setState(() {
                              final isMoveCorrect = droppedNumber == sudoku.solution[row][col];

                              if (!isMoveCorrect && droppedNumber != 0) {
                                _mistakeCount++;
                              }

                              sudoku.updateCell(row, col, droppedNumber);

                              if (_mistakeCount >= _mistakeLimit) {
                                _isGameOver = true;
                              } else if (_isBoardComplete()) {
                                _isGameWon = true;
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_isGameOver) _buildGameOverControls()
              else if (_isGameWon) Container() // Hide palette when won
              else _buildNumberPalette(),
            ],
          ),
        ),
        if (_isGameWon)
          Container(
            color: Colors.black.withOpacity(0.75),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Congratulations!',
                    style: TextStyle(fontSize: 48, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Close App'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      SystemNavigator.pop();
                    },
                  )
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGameOverControls() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "You Lost! Here is the solution.",
            style: TextStyle(fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text("Restart Game"),
            onPressed: () {
              setState(() {
                _resetGame();
                _isGameStarted = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNumberPalette() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            const Text(
              'Mistakes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '$_mistakeCount / $_mistakeLimit',
              style: TextStyle(
                fontSize: 20,
                color: _mistakeCount >= _mistakeLimit ? Colors.red : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        ...List.generate(9, (index) {
          final number = index + 1;
          return Draggable<int>(
            data: number,
            feedback: _buildDraggableFeedback(number.toString()),
            child: _buildNumberButton(number.toString()),
          );
        }),
        Draggable<int>(
          data: 0,
          feedback: _buildDraggableFeedback(Icons.backspace_outlined),
          child: _buildNumberButton(Icons.backspace_outlined),
        ),
      ],
    );
  }

  Widget _buildNumberButton(dynamic content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.blue.shade100,
        child: content is String
            ? Text(content, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
            : Icon(content as IconData, size: 20, color: Colors.black87),
      ),
    );
  }

  Widget _buildDraggableFeedback(dynamic content) {
    return Material(
      elevation: 4.0,
      color: Colors.transparent,
      child: CircleAvatar(
        radius: 25,
        backgroundColor: Colors.blue.shade300,
        child: content is String
            ? Text(content, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white))
            : Icon(content as IconData, size: 25, color: Colors.white),
      ),
    );
  }
}