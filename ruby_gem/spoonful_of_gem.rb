# tate opens the ruby chapter in seven languages in seven weeks by comparing ruby with "mary poppins" 
# someone who is quirky, beautiful, mysterious, magical. 
# he quotes the line "a spoonful of sugar makes the medicine go down" to describe syntactic sugar.
# ruby hides complexity behind things that just feel nice to write.
# this tool tries to have that same energy.

# runs on pure ruby stdlib. no bundle install. no irony lost hehe.

require_relative 'lib/gem_data'
require_relative 'lib/reporter'
require_relative 'lib/tarot'

# ARGV is a built-in array of command line arguments
# $stderr and $stdout are global objects. everything in ruby is an object,
# including the things that would be static utilities in java.
if ARGV.empty?
  $stderr.puts "usage: ruby spoonful_of_gem.rb path/to/Gemfile"
  exit 1
end

path = ARGV[0]

unless File.exist?(path)
  $stderr.puts "couldn't find a Gemfile at: #{path}"
  exit 1
end

Reporter.new(path).present