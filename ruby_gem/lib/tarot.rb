# lib/tarot.rb
#
# the corgi equivalent for gem_spoon.
# six characters, one drawn at random each run, animated character by character.
#
# how the animation works:
#   we print each character with a tiny sleep between them using $stdout.flush
#   normally ruby buffers output and prints it all at once at the end
#   $stdout.flush forces it to actually send each character immediately
#   this is the same trick every terminal progress bar uses
#
# how 24-bit color works:
#   \e[38;2;R;G;Bm sets foreground to that exact RGB value
#   \e[48;2;R;G;Bm sets background
#   \e[0m resets everything
#   windows terminal has supported this since 2019. we're fine.
#   the VT100 in 1978 could only do 8 colors. we have 16 million now.
#   same escape sequence mechanism. different numbers.

module Tarot

  # rgb() builds a 24-bit foreground color escape code
  # this is the thing the BBS ANSI artists of 1990 would have killed for
  def self.rgb(r, g, b)
    "\e[38;2;#{r};#{g};#{b}m"
  end

  # dim() makes text slightly transparent-feeling using the DIM attribute
  # it's a separate SGR code from color — they stack
  def self.dim
    "\e[2m"
  end

  def self.reset
    "\e[0m"
  end

  def self.bold
    "\e[1m"
  end

  # CARDS is an array of hashes. each card has:
  #   name: shown as the card title
  #   meaning: one line shown below the art
  #   art: array of strings, one per line
  #       each string is an array of [text, r, g, b] tuples
  #       so we can color individual parts of each line differently
  #
  # the format is verbose but explicit — you can see exactly what color
  # every character will be without running the code

  CARDS = [
    {
      name: "the governess",
      meaning: "impeccably maintained. mary poppins would approve of this gemfile.",
      art: [
        [ ["  ( · )  ", 199, 146, 234] ],
        [ ["  /|||\\  ", 199, 146, 234] ],
        [ [" /|||||\\  ", 126, 87,  194] ],
        [ ["  || ||   ", 126, 87,  194] ],
        [ ["  /\\  /\\  ", 130, 170, 255] ],
        [ [" ~~~", 199, 146, 234], ["☂", 255, 203, 107], ["~~~  ", 199, 146, 234] ],
      ]
    },
    {
      name: "the cheshire",
      meaning: "grinning at something you don't know yet. ancient gems lurk.",
      art: [
        [ [" /\\_____/\\ ", 255, 157,   0] ],
        [ ["( ^  ω  ^  )", 255, 255, 255] ],
        [ [" )         (  ", 255, 157,   0] ],
        [ [" (  ===  )   ", 84,  110, 122] ],
        [ ["  )       (   ", 255, 157,   0] ],
        [ [" (_________)  ", 84,  110, 122] ],
      ]
    },
    {
      name: "the crystal",
      meaning: "a gem, inspecting gems. it sees everything.",
      art: [
        [ ["    /\\    ", 255,  83, 112] ],
        [ ["   /  \\   ", 255, 203, 107] ],
        [ ["  / ", 137, 221, 255], ["✦", 255, 255, 255], ["  \\  ", 137, 221, 255] ],
        [ [" /      \\ ", 199, 146, 234] ],
        [ [" \\  ", 195, 232, 141], ["◆", 255, 255, 255], ["  / ", 195, 232, 141] ],
        [ ["  \\    /  ", 255, 203, 107] ],
        [ ["   \\  /   ", 255,  83, 112] ],
        [ ["    \\/    ", 137, 221, 255] ],
      ]
    },
    {
      name: "the witch",
      meaning: "deprecated methods in your future. she always knows first.",
      art: [
        [ ["  _____   ", 255, 203, 107] ],
        [ [" /     \\  ", 255, 203, 107] ],
        [ ["  (· ·)   ", 199, 146, 234] ],
        [ ["  \\___/   ", 199, 146, 234] ],
        [ [" /|||||\\  ", 199, 146, 234] ],
        [ ["  // \\\\   ", 84,  110, 122] ],
        [ [" *  ", 255, 203, 107], ["✦", 255, 255, 255], ["  *  ", 255, 203, 107] ],
      ]
    },
    {
      name: "the sparrow",
      meaning: "swift and healthy. your stack is moving.",
      art: [
        [ ["    __    ", 255, 255, 255] ],
        [ ["   /  \\   ", 255, 255, 255] ],
        [ ["  ( ·· )  ", 195, 232, 141] ],
        [ ["  _)  (_  ", 255, 255, 255] ],
        [ [" /  \\/  \\ ", 130, 170, 255] ],
        [ [" \\        / ", 130, 170, 255] ],
        [ ["  ~~  ~~  ", 255, 255, 255] ],
      ]
    },
    {
      name: "the clock",
      meaning: "time is the only honest critic. some of your gems have too much of it.",
      art: [
        [ ["  .-----. ", 84,  110, 122] ],
        [ [" /         \\ ", 84,  110, 122] ],
        [ ["| ", 84, 110, 122], ["  12  ", 255, 255, 255], ["   |", 84, 110, 122] ],
        [ ["| ", 84, 110, 122], ["9", 255, 255, 255], ["  ", 84, 110, 122], ["⬤", 255, 83, 112], ["  ", 84, 110, 122], ["3", 255, 255, 255], [" |", 84, 110, 122] ],
        [ ["| ", 84, 110, 122], ["   6   ", 255, 255, 255], ["  |", 84, 110, 122] ],
        [ [" \\         / ", 84,  110, 122] ],
        [ ["  '-----' ", 84,  110, 122] ],
      ]
    }
  ]

  # sparkle_char() — the heart of the new animation
  #
  # for a single target character, this prints a few flicker frames
  # before resolving into the real thing. how it works:
  #
  #   1. pick a random glyph from NOISE_CHARS
  #   2. print it in a dim, color-shifted version of the real color
  #   3. move the cursor back one character (\e[1D) — no newline, no clearing
  #   4. repeat a few times, slowing down each frame (easing)
  #   5. print the real character in full color
  #
  # the cursor-back trick (\e[1D) is what makes overwriting work in terminals.
  # it's the same mechanism used by every spinner and progress bar.
  # we're just using it to fake randomness resolving into truth.
  #
  # spaces are skipped — flickering a space looks like nothing and costs time.
  # multi-byte unicode chars (☂ ✦ ◆ ⬤ ω) are treated as one unit by chars(),
  # but \e[1D only moves back one column-width. most terminals render those
  # at single width, so it works. if yours doesn't, that's a terminal quirk.

  NOISE_CHARS = %w[
    ░ ▒ ▓ ╳ ╬ ╫ ╪ ┼ ┽ ╂ ╆ ╅ ╄ ╇ ╈ ╉ ╊
    ∴ ∵ ∶ ∷ ≈ ≋ ≌ ∞ ∿ ≀ ⁂ ※ ⌘ ⌥ ⌦ ⎔
    ✧ ✦ ✶ ✸ ✹ ✺ ❋ ❊ ❉ ❈ ❇ ❆ ❅ ❄ ❃
    ◈ ◉ ◊ ○ ◌ ◍ ◎ ● ◐ ◑ ◒ ◓ ◔ ◕ ◖ ◗
    ⟐ ⟡ ⟢ ⟣ ⟤ ⟥ ⬡ ⬢ ⬣ ⬟ ⬠
  ].freeze

  # eased_sleeps() returns an array of sleep durations for flicker frames.
  # starts fast (chaotic), slows down as it converges on the real character.
  # this mimics physical systems settling — like a compass needle finding north.
  def self.eased_sleeps(frames)
    frames.times.map { |i| 0.025 + (i.to_f / frames) * 0.055 }
  end

  # dim_shift() returns a slightly desaturated version of the real color,
  # used for noise frames so they read as "not quite right" versus the final.
  def self.dim_shift(r, g, b)
    # push each channel toward 120 (mid-grey) by 40% and add slight blue cast
    dr = (r + (120 - r) * 0.4).to_i
    dg = (g + (120 - g) * 0.4).to_i
    db = [b + 30, 200].min
    rgb(dr, dg, db)
  end

  def self.sparkle_char(char, color, r, g, b)
    if char =~ /\s/
      # spaces just print instantly — no flicker needed
      print char
      $stdout.flush
      sleep(0.008)
      return
    end

    noise_color = dim_shift(r, g, b)
    frames      = rand(2..4)   # each char gets a slightly different number of flickers
    sleeps      = eased_sleeps(frames)

    frames.times do |i|
      noise = NOISE_CHARS.sample
      print "#{dim}#{noise_color}#{noise}#{reset}"
      $stdout.flush
      sleep(sleeps[i])
      print "\e[1D"   # cursor back one — overwrites the noise char
    end

    # final reveal: the real character in full color
    print "#{color}#{char}#{reset}"
    $stdout.flush
    sleep(0.018)   # brief pause after resolving — gives it weight
  end

  # pick() — chooses a card based on what the analysis actually found.
  #
  # the card is not random. it's a reading. the gemfile earned it.
  #
  # gems is an array of GemData objects (both found and not found).
  # we compute a handful of signals and score each card against them.
  # highest score wins. ties go to the card listed first — also not random,
  # just stable. same gemfile, same card, every time.
  #
  # signal                  card it favors
  # ──────────────────────────────────────
  # all recent, all found   the governess  (impeccable order)
  # many ancient gems       the cheshire   (lurking rot)
  # ecosystem pillars       the crystal    (load-bearing, seen everything)
  # deprecated warnings     the witch      (the future is visible)
  # majority thriving       the sparrow    (moving fast, healthy)
  # many old, some missing  the clock      (time is the critic)

  CARD_INDEX = {
    "the governess" => 0,
    "the cheshire"  => 1,
    "the crystal"   => 2,
    "the witch"     => 3,
    "the sparrow"   => 4,
    "the clock"     => 5,
  }.freeze

  def self.pick(gems)
    found   = gems.select(&:found?)
    missing = gems.reject(&:found?)

    return CARDS.first if found.empty?

    total          = found.size.to_f
    ancient        = found.count(&:ancient?)
    thriving       = found.count(&:thriving?)
    beloved        = found.count(&:beloved?)    # now means 1B+ downloads
    ancient_ratio  = ancient  / total
    thriving_ratio = thriving / total
    beloved_ratio  = beloved  / total
    missing_ratio  = missing.size / gems.size.to_f

    # ── the two axes that actually differentiate gemfiles ──────────────────
    #
    # ancient_ratio  →  how much of this stack is rotting
    # thriving_ratio →  how much is actively moving
    #
    # they can both be low (a stable-but-stale middle), both nonzero
    # (a mixed bag), or one dominant. beloved_ratio is now a tiebreaker,
    # not a primary signal, because at 1B+ it's genuinely rare.
    #
    #  ancient high, thriving low  →  cheshire or clock (rot dominates)
    #  ancient low, thriving high  →  sparrow or governess (health dominates)
    #  ancient low, thriving low   →  governess (clean, maybe just stable)
    #  ancient mid, thriving mid   →  witch (ambiguous, she reads both)
    #  beloved dominant            →  crystal (only when truly load-bearing)

    scores = Hash.new(0)

    # the governess — clean bill of health. no rot, no missing.
    scores["the governess"] += 6  if ancient.zero? && missing.empty?
    scores["the governess"] += 2  if thriving_ratio > 0.4
    scores["the governess"] -= 6  if ancient_ratio > 0.15   # any real rot disqualifies her

    # the cheshire — rot is the dominant story, not much thriving
    scores["the cheshire"]  += (ancient_ratio * 12).round
    scores["the cheshire"]  += 3  if ancient_ratio > 0.5
    scores["the cheshire"]  -= 4  if thriving_ratio > 0.4   # thriving cancels cheshire

    # the crystal — true pillars (1B+) make up a meaningful share
    scores["the crystal"]   += (beloved_ratio * 12).round
    scores["the crystal"]   += 4  if beloved_ratio > 0.3
    scores["the crystal"]   -= 3  if ancient_ratio > 0.25   # rot muddies a pillar reading

    # the witch — the both/and card. ancient AND thriving coexist.
    scores["the witch"]     += 4  if ancient > 0 && thriving > 0
    scores["the witch"]     += 3  if ancient_ratio.between?(0.1, 0.5)
    scores["the witch"]     += 2  if thriving_ratio.between?(0.2, 0.6)
    scores["the witch"]     -= 3  if ancient_ratio > 0.55   # too far gone — cheshire
    scores["the witch"]     -= 3  if ancient.zero?           # too clean — governess

    # the sparrow — thriving is dominant, ancient is negligible
    scores["the sparrow"]   += (thriving_ratio * 12).round
    scores["the sparrow"]   += 3  if thriving_ratio > 0.6
    scores["the sparrow"]   -= 5  if ancient_ratio > 0.2    # any real rot grounds the sparrow

    # the clock — ancient is significant, missing gems too, overall stale
    scores["the clock"]     += (ancient_ratio * 10).round
    scores["the clock"]     += 3  if ancient_ratio > 0.35
    scores["the clock"]     += 2  if missing_ratio > 0.1
    scores["the clock"]     -= 4  if thriving_ratio > 0.45  # too much life for the clock

    winner = scores.max_by { |_, score| score }.first
    CARDS[CARD_INDEX[winner]]
  end

  # draw() animates a specific card to the terminal.
  # call Tarot.draw(Tarot.pick(gems)) from Reporter after analysis is complete.
  #
  # structure: border + name printed instantly (they frame what's coming),
  # then art lines animate character-by-character with sparkle_char(),
  # then meaning fades in word-by-word with a gentler delay.

  def self.draw(card = CARDS.sample)
    width = 24

    puts "\n"

    # ── frame top + name: printed instantly to establish the stage ──────────
    puts "  #{rgb(84, 110, 122)}╔#{"═" * (width + 2)}╗#{reset}"

    name_padded = card[:name].center(width)
    puts "  #{rgb(84, 110, 122)}║ #{bold}#{rgb(255, 203, 107)}#{name_padded}#{reset} #{rgb(84, 110, 122)}║#{reset}"

    puts "  #{rgb(84, 110, 122)}╠#{"═" * (width + 2)}╣#{reset}"

    # ── art: the sparkle reveal happens here ────────────────────────────────
    card[:art].each do |line_segments|
      print "  #{rgb(84, 110, 122)}║ #{reset}"

      line_text = line_segments.map { |seg| seg[0] }.join

      line_segments.each do |segment|
        text, r, g, b = segment
        color = rgb(r, g, b)

        text.chars.each do |char|
          sparkle_char(char, color, r, g, b)
        end
      end

      padding = width - line_text.length + 1
      puts "#{" " * [padding, 0].max}#{rgb(84, 110, 122)}║#{reset}"
    end

    # ── divider before meaning ───────────────────────────────────────────────
    puts "  #{rgb(84, 110, 122)}╠#{"═" * (width + 2)}╣#{reset}"

    # ── meaning: word by word, quieter pace ─────────────────────────────────
    meaning_words = card[:meaning].split
    meaning_lines = []
    current = ""
    meaning_words.each do |word|
      if (current + " " + word).strip.length <= width
        current = (current + " " + word).strip
      else
        meaning_lines << current
        current = word
      end
    end
    meaning_lines << current unless current.empty?

    meaning_lines.each do |mline|
      # render the full padded line, then animate it word-by-word
      # we build it character by character for consistent spacing
      padded  = mline.ljust(width)
      print "  #{rgb(84, 110, 122)}║ #{dim}#{reset}"

      padded.chars.each do |char|
        print "#{dim}#{rgb(168, 178, 216)}#{char}#{reset}"
        $stdout.flush
        sleep(0.028)   # slower than art — meaning lands after the image
      end

      puts " #{rgb(84, 110, 122)}║#{reset}"
    end

    puts "  #{rgb(84, 110, 122)}╚#{"═" * (width + 2)}╝#{reset}"
    puts "\n"
  end

end