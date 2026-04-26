import java.util.Scanner;

public class TicTacToe {

    // multiline string without a single escape character.
    static String TITLE = """ 
TIC 
TAC 
TOE  
            """;

    static char[] board = {'1','2','3','4','5','6','7','8','9'};
    static int moves = 0;
// board layout string format
    static void printBoard() {
        System.out.println(String.format(
            "\n %s | %s | %s\n---|---|---\n %s | %s | %s\n---|---|---\n %s | %s | %s\n",
            board[0], board[1], board[2],
            board[3], board[4], board[5],
            board[6], board[7], board[8]
        ));
    }
// win conditions lookup table
    static boolean checkWin(char s) {
        return (board[0]==s && board[1]==s && board[2]==s) ||
               (board[3]==s && board[4]==s && board[5]==s) ||
               (board[6]==s && board[7]==s && board[8]==s) ||
               (board[0]==s && board[3]==s && board[6]==s) ||
               (board[1]==s && board[4]==s && board[7]==s) ||
               (board[2]==s && board[5]==s && board[8]==s) ||
               (board[0]==s && board[4]==s && board[8]==s) ||
               (board[2]==s && board[4]==s && board[6]==s);
    }
// loser math random produces a double from 0.0 to 0.99 cast to int to get an index. slightly chaotic. perfect for trash talk.
    static String pickLine(String loser) {
        String[] lines = {
            loser + " played like they were using a trackpad.",
            "Somewhere, " + loser + "'s rubber duck is disappointed.",
            loser + " should consider a career in something non competitive.",
            "The board has been reset. " + loser + "'s dignity has not."
        };
        return lines[(int)(Math.random() * lines.length)];
    }

    public static void main(String[] args) {
        var scanner = new Scanner(System.in);
        var names = new String[2];
        var symbols = new char[]{'X', 'O'};

        System.out.println(TITLE);

        System.out.print("Player 1 name: ");
        names[0] = scanner.nextLine();

        System.out.print("Player 2 name: ");
        names[1] = scanner.nextLine();
// ternary
        var goesFirst = names[0];
        System.out.println(goesFirst + " goes first. " +
            (goesFirst.length() > 9
                ? "That name is longer than this game is going to last."
                : "Good luck."));

        printBoard();

        gameLoop:
        while (true) {
            var turn = moves % 2;
            var symbol = symbols[turn];
            var name = names[turn];

            System.out.print(name + " [" + symbol + "] pick a square (1-9): ");
// invaild input
            int pos;
            try {
                pos = scanner.nextInt() - 1;
            } catch (Exception e) {
                System.out.println("That's not a number. Incredible.");
                scanner.next();
                continue;
            }
// invalid move
            if (pos < 0 || pos > 8 || board[pos] == 'X' || board[pos] == 'O') {
                System.out.println("That square is taken. Or imaginary. Either way, no.");
                continue;
            }

            board[pos] = symbol;
            moves++;

            printBoard();
// winner
            if (checkWin(symbol)) {
                var loser = names[1 - turn];
                System.out.println("--- " + name + " wins ---");
                System.out.println(pickLine(loser));
                break gameLoop;
            }
// draw
            if (moves == 9) {
                System.out.println("Draw. You are both equally hard to read.");
                break gameLoop;
            }
        }
// thanks
        System.out.println("\nThanks for playing,");
        for (var name : names) {
            System.out.println("  - " + name);
        }

        scanner.close();
    }
}
