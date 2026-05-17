# things i found out about ruby

bruce tate opens the ruby chapter in seven languages in seven weeks by calling ruby "mary poppins." quirky, beautiful, mysterious, magical. he quotes the line "a spoonful of sugar makes the medicine go down" to describe syntactic sugar the idea that ruby hides complexity behind syntax so pleasant you barely notice you're doing work. this whole project is an attempt to build something with that same energy.

## on the language itself

ruby was designed around the programmer, not the machine. yukihiro matsumoto (matz) said explicitly that he optimized for developer happiness, not execution speed. this is written into the actual design philosophy documentation. a language with a stated emotional goal.

everything is an object. not "almost everything" like java. everything. `nil` is an object (`NilClass`). `true` is an object (`TrueClass`). integers are objects — you can call `42.times { puts "hello" }` and it works. this comes from smalltalk, which ruby borrowed heavily from.

nil is not null. in java, null is the absence of an object — a void in memory. in ruby, `nil` is an actual instance of `NilClass`. it has methods. you can call `nil.to_s` (returns `""`) or `nil.to_a` (returns `[]`). nil is something, not nothing. this matters more than it sounds.

the safe navigation operator `&.` was added in ruby 2.3. `object&.method` returns nil if object is nil instead of raising NoMethodError. kotlin and swift have the same thing (`?.`). ruby got there in 2015. it's the reason `match(...)&.captures&.first` in this codebase doesn't blow up on strings that don't match.

blocks are not lambdas, procs, or methods. ruby has four different callable things and they behave differently around `return`, argument checking, and arity. blocks are the lightweight anonymous ones — `{ |x| x * 2 }` or `do |x| x * 2 end`. the `do/end` vs `{}` distinction is stylistic by convention (multiline = do/end, inline = {}) but mechanically they differ in operator precedence in edge cases.

`map(&:method_name)` is shorthand for `map { |x| x.method_name }`.** the `&` converts a Symbol to a Proc by calling `.to_proc` on it. Symbol#to_proc is defined in the stdlib and returns a proc that calls that method name on whatever it receives. this is one of the most idiomatic patterns in ruby and one of the first things that reads as magic until you know what it's doing.

## on open classes

you can reopen any class in ruby, including the built-in ones. String, Integer, Array, NilClass — all open. this is called "monkey patching" when done carelessly and "core extensions" when done with intention. rails does this extensively: `"hello".pluralize`, `5.days.ago`, `[].second` — none of those are standard ruby. rails added them to existing classes.

"duck punching" is the aggressive version. if you reopen a class and *redefine* an existing method, that's not extending behavior, that's replacing it. tate quotes the term: "if this duck is not giving you the noise that you want, you've got to just punch that duck until it returns what you expect." the ruby community has strong opinions about when this is acceptable. the answer is usually: not often.

`method_missing` is not slow by default, but it's not free either. every time ruby can't find a method, it walks up the ancestor chain before calling method_missing. in hot paths (tight loops, frequent calls) this matters. for a CLI tool that runs once: fine. for a rails model called ten thousand times per request: be careful.

always define `respond_to_missing?` alongside `method_missing`. this is the known gotcha. `method_missing` makes the method work. `respond_to_missing?` makes `respond_to?(:the_dynamic_method)` return true. if you don't define it, introspection breaks and other code that checks for a method before calling it will silently skip your dynamic methods. ruby style guides consider this a required pairing.

## on mixins and modules

ruby has no multiple inheritance but you can include as many modules as you want. this is deliberate. matz looked at the diamond problem in C++ and decided the cure was worse than the disease. modules give you behavior sharing without the ambiguity of two parent classes defining the same method.

the `Comparable` module is one of the best examples of how ruby's design pays off. define one method (`<=>`, the spaceship operator) and you get `<`, `>`, `<=`, `>=`, `between?`, `clamp`, and correct behavior in `sort`, `min`, `max`, `sort_by` automatically. one method, seven behaviors. in java you implement `Comparable<T>` and get `compareTo`. you still have to define the rest yourself or use `Comparator`.

`Enumerable` is the module ruby open source devs will look for first. if your class represents a collection of things, include `Enumerable`, define `each`, and you immediately get `map`, `select`, `reject`, `find`, `group_by`, `min_by`, `max_by`, `sort_by`, `sum`, `count`, `any?`, `all?`, `none?`, `flat_map`, `zip`, `chunk`, `tally`, and about 50 more. it's the module that makes ruby feel productive.

## on the rubygems ecosystem

rubygems.org's public API requires no authentication for read operations. `GET https://rubygems.org/api/v1/gems/GEM_NAME.json` returns full metadata — downloads, version, dates, description, authors — for any public gem. no api key, no signup, no rate limiting headers in normal usage. this whole project runs on that single endpoint.

the downloads count on rubygems.org is cumulative across all versions, all time. when a gem shows 900 million downloads it means every `bundle install` that ever included that gem across every version. it's a proxy for ecosystem centrality, not popularity in the social sense. nokogiri has over a billion. it's not because developers love xml parsing.

gem versions follow semver but `~>` is ruby's interpretation of it. `~> 7.1` means `>= 7.1` and `< 8`. `~> 7.1.0` means `>= 7.1.0` and `< 7.2`. the tilde-arrow is called the "pessimistic constraint operator." it's pessimistic because it assumes the next major (or minor) version might break things. cautious but reasonable.

## on this project

built in ruby 4.0 on windows (rubyinstaller + devkit). zero external gems — only stdlib: `net/http`, `json`, `date`. the irony of a gem analysis tool that needs no gems was not lost on me.

inspired by bruce tate's seven languages in seven weeks (pragmatic programmers, 2010). ruby is week 1 in that book. it's week 3 here, after java and algol 68. the lineage is as shown.

```
java (1995, algol family)
  ↓ cleaned up c++ syntax
algol 68 (1968, where structured programming began)
  ↓ invented the block, the procedure, the struct
ruby (1995, smalltalk + lisp + perl)
  ↓ made all of it feel like writing a letter
```