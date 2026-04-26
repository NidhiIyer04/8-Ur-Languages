public class hello_CAFEBABE {
    public static void main(String[] args) {
        String mood = "confused";
        int coffees = 0;
        boolean understandsJava = false;

        System.out.println("Current mood: " + mood);
        System.out.println("Coffees consumed: " + coffees);
        System.out.println("Understands Java: " + understandsJava);

        coffees = 3;
        mood = "chaotic but saner";
        understandsJava = true; // i'm being optimistic

        System.out.println("Current mood: " + mood);
        System.out.println("Coffees consumed: " + coffees);
        System.out.println("Understands Java: " + understandsJava);
    }
}
