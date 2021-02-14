# `with_clues` - temporarily provide more context whena test fails. Beats `puts`

Suppose you have this:

```ruby
expect(page).to have_content("My Awesome Site")
```

And Capybara says that that content is not there and that is all it says.  You might slap in a `puts page.html` and try again.
Instead, what if you could not do that and do this?

```ruby
with_clues do
  expect(page).to have_content("My Awesome Site")
end
```

And *that* would print out your HTML?  Or your JavaScript console?  Or whatever else?  Neat, right?

## Install

```
gem install with_clues
```

Or, in `Gemfile`:

```ruby
gem "with_clues"
```

For Rails, you might want to do this:

```ruby
gem "with_clues", group: :test
```

Then `bundle install`

## Use

Bet thing to do is mix into your base test class.

### For Minitest

If you are using Rails, probably something like this:

```ruby
# test/test_helper.rb
require "with_clues"

class ActiveSupport::TestCase
  include WithClues::Method

  # ...
end
```

If you aren't using Rails, add the `require` and `include` wherever you configure your base test case (or just put it in each test individually).

### For RSpec

You'll want to put this in your `spec/spec_helper.rb` file:

```ruby
require "with_clues"
RSpec.configure do |c|
  c.include WithClues::Method
end
```

