public class labeled_break {
    public static void main(String[] args) {
        outer: // lable
        for (int i = 0; i < 5; i++) {
            for (int j = 0; j < 5; j++) {
                if (i == 2 && j == 3) {
                    System.out.println("Found it at " + i + "," + j + " escaping both loops!");
                    break outer;  // jumps ALL the way out, not just the inner loop
                }
            }
        }

        System.out.println("Its out!");
    }
}

