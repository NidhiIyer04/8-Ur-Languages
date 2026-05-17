# lib/reporter.rb
#
# this file has the mary poppins energy.
# the report is never cruel. it's just... accurate. warmly, precisely accurate.
# "a spoonful of sugar" - tate uses this to describe how ruby wraps
# difficult truths in syntax so pleasant you barely notice you're doing work.
#
# metaprogramming lives here too: method_missing makes the Reporter
# respond to dynamic queries like .gems_older_than_2_years
# as if those methods were defined. they weren't. ruby figured it out.

require_relative 'gem_data'
require_relative 'tarot'

# --------------------------------------------------------
# Reportable module
#
# handles all the formatting and printing concerns
# kept separate from Reporter because "how to display" is
# different from "what to analyze." they change for different reasons.
# --------------------------------------------------------

module Reportable
  # terminal color codes. not a gem, just escape sequences.
  # works on any unix terminal including windows terminal on modern windows.
  RESET  = "\e[0m"
  BOLD   = "\e[1m"
  DIM    = "\e[2m"
  GREEN  = "\e[32m"
  YELLOW = "\e[33m"
  CYAN   = "\e[36m"
  SOFT   = "\e[37m"

  def header(text)
    puts "\n#{BOLD}#{CYAN}#{text}#{RESET}"
    puts "#{DIM}#{"─" * text.length}#{RESET}"
  end

  def row(label, value, color = RESET)
    puts "  #{SOFT}#{label.fit(28)}#{RESET}#{color}#{value}#{RESET}"
  end

  def note(text)
    puts "  #{DIM}#{text}#{RESET}"
  end

  def spacer
    puts ""
  end

  def verdict_line(emoji, text)
    puts "  #{emoji}  #{text}"
  end
end

# --------------------------------------------------------
# Reporter - the main analysis class
#
# include Reportable for display methods
# method_missing handles dynamic queries - the DSL-like interface
#
# method_missing is called by ruby whenever a method doesn't exist
# instead of immediately raising NoMethodError, ruby gives you a chance
# to handle the call yourself. tate covers this in day 3.
# it's how rails' dynamic finders worked: User.find_by_email("x@y.com")
# no find_by_email method existed. method_missing caught it and built the query.
# --------------------------------------------------------

class Reporter
  include Reportable

  def initialize(path)
    @path = path
    @parser = GemfileParser.new(path)
    @gems  = @parser.parse
  end

  # --------------------------------------------------------
  # method_missing - the magic trick
  #
  # if you call reporter.gems_older_than_3_years ruby looks for that method,
  # doesn't find it, and calls method_missing instead with the method name as a symbol.
  # we parse the name, extract the number, and return the right subset.
  # to ruby open source devs reading the repo: this is the line that earns the star.
  # --------------------------------------------------------

  def method_missing(name, *args)
    case name.to_s
    when /^gems_older_than_(\d+)_years?$/
      years = $1.to_i   # $1 is the first regex capture group. a ruby global.
      @gems.select { |g| g.days_since_update && g.days_since_update > years * 365 }
    when /^gems_updated_within_(\d+)_days?$/
      days = $1.to_i
      @gems.select { |g| g.days_since_update && g.days_since_update <= days }
    when /^gems_with_over_(\d+)_million_downloads?$/
      millions = $1.to_i
      @gems.select { |g| g.downloads && g.downloads > millions * 1_000_000 }
    else
      super   # not our business. pass it up to the default NoMethodError.
    end
  end

  # respond_to_missing? is method_missing's polite companion
  # without it, respond_to?(:gems_older_than_2_years) returns false even though
  # the method works. always define this alongside method_missing.
  # ruby open source maintainers will check for this. it's a known gotcha.
  def respond_to_missing?(name, include_private = false)
    name.to_s.match?(/^gems_(older_than|updated_within|with_over)_\d+/) || super
  end

  def present
    spacer
    puts "#{BOLD}  ✦ gem spoon#{RESET}  #{DIM}— a spoonful of clarity#{RESET}"
    puts "  #{DIM}analyzing: #{@path}#{RESET}"
    spacer

    found     = @gems.select(&:found?)       # &:found? shorthand for { |g| g.found? }
    not_found = @gems.reject(&:found?)       # reject is select's opposite

    show_overview(found, not_found)
    show_needs_attention(found)
    show_thriving(found)
    show_beloved(found)
    show_not_found(not_found) if not_found.any?
    show_verdict(found, not_found)

    Tarot.draw(Tarot.pick(@gems))
  end

  private

  def show_overview(found, not_found)
    total_downloads = found.sum { |g| g.downloads.to_i }
    # .sum with a block is enumerable doing the thing it does best
    # no loop variable, no accumulator, just describe what you want summed

    header "overview"
    row "gemfile",         @path
    row "gems found",      "#{found.size} of #{@gems.size}"
    row "total downloads", format_number(total_downloads)
    row "most downloaded", found.max_by(&:downloads)&.name.to_s
    row "most recent",     found.min_by(&:days_since_update)&.name.to_s
    row "most ancient",    found.max_by(&:days_since_update)&.name.to_s
    # max_by and min_by are Enumerable methods - ruby's most useful module
    # every class that includes Enumerable and defines each() gets these for free
    # Array includes it. your custom collections can too.
  end

  def show_needs_attention(found)
    # using method_missing right here. calling a method that doesn't exist.
    # ruby intercepts it, parses "2" from the name, filters the array.
    sleepy = gems_older_than_2_years

    return if sleepy.empty?

    header "needs a look"
    note "these gems haven't had a release in over two years."
    note "they might be perfectly stable. they might be perfectly abandoned."
    spacer

    sleepy.sort.each do |gem|
      # .sort works because GemData includes Comparable and defines <=>
      # we get sorted-by-age for free
      label = "#{gem.name} #{DIM}(#{gem.version})#{RESET}"
      row label, gem.age_label, YELLOW
    end
  end

  def show_thriving(found)
    active = gems_updated_within_90_days

    return if active.empty?

    header "actively maintained"
    note "updated in the last 90 days. someone is minding the shop."
    spacer

    active.sort.each do |gem|
      row gem.name.fit(28), gem.age_label, GREEN
    end
  end

  def show_beloved(found)
    # 1 billion downloads is the real line for "load-bearing for all of ruby"
    pillars = gems_with_over_1000_million_downloads

    return if pillars.empty?

    header "pillars of the ecosystem"
    note "these gems are in a significant portion of ruby projects everywhere."
    note "you are not special for using them. neither is anyone else. that's the point."
    spacer

    pillars.sort_by { |g| -g.downloads.to_i }.each do |gem|
      row gem.name, format_number(gem.downloads), CYAN
    end
  end

  def show_not_found(not_found)
    header "not found on rubygems.org"
    note "typo, private gem, git source, or path gem. gem spoon can't see those."
    spacer

    not_found.each { |gem| row gem.name, "—", DIM }
  end

  def show_verdict(found, not_found)
    spacer
    header "the verdict"
    spacer

    ancient_count  = gems_older_than_2_years.size
    healthy_count  = gems_updated_within_90_days.size
    missing_count  = not_found.size

    verdict_line "✦", "#{found.size} gems analyzed, #{missing_count} not found"

    if ancient_count.zero?
      verdict_line "✦", "everything has had attention in the last two years. well tended."
    elsif ancient_count == 1
      verdict_line "✦", "one gem is showing its age. worth a glance."
    else
      verdict_line "✦", "#{ancient_count} gems last updated over two years ago."
    end

    if healthy_count > found.size / 2
      verdict_line "✦", "more than half your stack is actively maintained. that's genuinely good."
    end

    spacer
    puts "  #{DIM}a well-tended Gemfile is its own kind of magic.#{RESET}"
    spacer
  end

  # format_number turns 94823719 into "94,823,719"
  # this would be NumberFormat.getInstance().format() in java
  # in ruby: one line, no imports, no instances
  def format_number(n)
    n.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end