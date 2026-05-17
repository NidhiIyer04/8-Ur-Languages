# three ruby things happening in this file:
#   1. open classes  - we reopen String to teach it a new trick
#   2. modules       - Fetchable is a mixin, not a parent class
#   3. Comparable    - ruby's built-in mixin for sorting, mixed into GemData

require 'net/http'
require 'json'
require 'date'

# --------------------------------------------------------
# open classes - one of ruby's most famous features
#
# in java, String is final. sealed. you cannot touch it.
# in ruby, every class is open. always. you can reopen String
# right now and add methods to it and every String in the
# program gets them instantly.
#
# tate covers this on day 3. he calls it powerful and warns it
# can create "impressive messes" if abused. the rule of thumb
# ruby devs use: only do this if it genuinely reads like english
# and you'd want it on every single instance of the class.
#
# here: gemfile lines look like 'gem "rails", "~> 7.0"'
# we want String to know how to clean itself into a gem name.
# that's a reasonable thing to want every string to do in this context.
# --------------------------------------------------------

class String
  # strips gem "..." lines down to just the name
  # "  gem 'devise', '~> 4.9'  " -> "devise"
  def to_gem_slug
    match(/gem\s+['"]([^'"]+)['"]/i)&.captures&.first&.strip
    # &. is the safe navigation operator - like ?. in kotlin
    # if match() returns nil, &. short-circuits instead of blowing up
    # this is ruby being protective without making you write if/else
  end

  # pads or truncates a string to exactly n characters
  # used for aligning columns in the report
  def fit(n)
    self[0, n].ljust(n)
  end
end

# --------------------------------------------------------
# Fetchable module - the mixin that handles rubygems.org API calls
#
# a module in ruby is like a java interface that's allowed to have
# method bodies. you mix it into a class with `include` and the class
# gets all the methods as if they were defined there.
#
# the key difference from inheritance: you can include many modules.
# no diamond problem, no forced hierarchy.
# tate: "mixins give you a way to share behavior without the brittleness
# of multiple inheritance."
#
# Fetchable is separate from GemData because fetching is a concern,
# not an identity. GemData IS a gem. it DOES fetching. that's the split.
# --------------------------------------------------------

module Fetchable
  BASE_URL = "https://rubygems.org/api/v1/gems"

  # returns parsed json hash or nil if anything goes wrong
  # we fail silently because one dead gem shouldn't kill the whole report
  def fetch_gem_info(name)
    uri = URI("#{BASE_URL}/#{name}.json")

    response = Net::HTTP.get_response(uri)
    return nil unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue StandardError
    # rescue with no specific class catches everything
    # not usually best practice but fine for a CLI tool where
    # network errors, json errors, and encoding errors all mean the same thing: skip it
    nil
  end
end

# --------------------------------------------------------
# GemData - the main class
#
# includes two modules: Fetchable for API calls, Comparable for sorting
# Comparable is from ruby's stdlib - mix it in, define <=> (spaceship operator)
# and you get <, >, <=, >=, between?, clamp, and sort for free
# this is the enumerable/comparable pattern tate talks about in day 2
# --------------------------------------------------------

class GemData
  include Fetchable
  include Comparable

  attr_reader :name, :version, :downloads, :updated_at, :description, :info

  # attr_reader is metaprogramming shorthand
  # it defines a getter method for each symbol
  # attr_reader :name creates: def name; @name; end
  # in java this is six lines per field. here it's one line for all of them.

  def initialize(name)
    @name = name
    @info = fetch_gem_info(name)    # hits the rubygems.org API on creation
    parse_info if @info
  end

  def found?
    !@info.nil?
  end

  def days_since_update
    return nil unless @updated_at
    (Date.today - @updated_at).to_i
  end

  def ancient?
    days_since_update && days_since_update > 730   # 2 years
  end

  def thriving?
    days_since_update && days_since_update < 90
  end

  def beloved?
    # 1 billion downloads is the real threshold for "load-bearing for all of ruby"
    # 100M was too low — coffee-rails, uglifier, turbolinks all cleared it, and those
    # are relics, not pillars. rack, nokogiri, activesupport clear 1B. that's the line.
    @downloads && @downloads > 1_000_000_000
  end

  # spaceship operator - required by Comparable
  # returns -1, 0, or 1. ruby uses this to make everything else work.
  # once you define this, Array#sort just works on GemData objects.
  def <=>(other)
    days_since_update.to_i <=> other.days_since_update.to_i
  end

  def age_label
    d = days_since_update
    return "unknown" unless d

    case d
    when 0..30    then "updated this month"
    when 31..90   then "updated recently"
    when 91..365  then "updated this year"
    when 366..730 then "getting on a bit"
    else               "last seen in #{@updated_at&.year}"
    end
    # case/when in ruby works on ranges. "when 0..30" checks if d is in that range.
    # in java you'd need if/else chains or a switch with >= and <=.
    # ruby's case is an expression too - it returns a value, just like IF in algol 68.
  end

  private

  def parse_info
    @version     = @info['version']
    @downloads   = @info['downloads']
    @description = @info['info']&.strip

    raw_date = @info['version_created_at'] || @info['created_at']
    @updated_at = Date.parse(raw_date) if raw_date
  rescue ArgumentError
    @updated_at = nil
  end
end

# --------------------------------------------------------
# GemfileParser - reads a Gemfile, returns GemData objects
#
# this is a plain class, no modules. not everything needs a mixin.
# knowing when NOT to use a feature is part of thinking in ruby.
# --------------------------------------------------------

class GemfileParser
  def initialize(path)
    @path = path
  end

  def parse
    lines = File.readlines(@path)

    gem_names = lines
      .map(&:to_gem_slug)     # & converts a method name to a block. map(&:to_gem_slug)
      .compact                # means: for each element call .to_gem_slug on it
                              # compact removes nils - lines that weren't gem declarations
                              # .map(&:method) is one of the most idiomatic ruby patterns

    puts "  fetching #{gem_names.size} gems from rubygems.org...\n\n"

    # .map here returns an array of GemData objects
    # each GemData hits the API in its initialize. straightforward, readable.
    gem_names.map { |name| GemData.new(name) }
    # { |name| ... } is a block - an anonymous chunk of code passed to map
    # tate covers blocks in day 2. they're central to how ruby thinks about iteration.
  end
end