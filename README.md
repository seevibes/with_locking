# WithLocking

A gem to execute a block of code and ensure that one does not execute other code until the block has completed executing. 

## Installation

Add this line to your application's Gemfile:

    gem 'with_locking'

Or install it yourself as:

    $ gem install with_locking

## Usage

A block of code can be executed like so:

    WithLocking.do { puts "While I'm running other code run through WithLocking cannot run!" }

Alternatively, run the block of code with an optional name (recommended), that way multiple WithLocking blocks with different names can be invoked without conflicting:

    WithLocking.do(:name => "sleeper") { sleep 60 }
    WithLocking.do(:name => "sleeper") { puts "I won't run because sleeper is still running the first block." }

To just test if a named block is still running use `locked?`:

    WithLocking.locked?("sleeper")
    # => true or false

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request