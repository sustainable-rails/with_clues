# `with_clues` - temporarily provide more context when tests fail. Beats `puts`

Suppose you have this:

```ruby
expect(page).to have_content("My Awesome Site")
```

And Capybara says that that content is not there and that is all it says.  You might slap in a `puts page.html` and try again. Instead, what if you could not do that and do this?

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

## Setup

Best thing to do is mix into your base test class.

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

## Use

In general, you would not want to wrap all tests with `with_clues`.  This is a diagnostic tool to allow you to get more information on a test that is failing.  As such, your workflow might be:

1. Notice a test failing that you cannot easily diagnose
1. Wrap the failing assertion in `with_clues`:

   ```ruby
   with_clues do
     expect(page).to have_selector("div.foo.bar")
   end
   ```
1. Run the test again, and see the additional info.
1. Once you've made the test pass, remove `with_clues`

## Included Clues

There are three clues included:

* Dumping HTML - when `page` exists, it will dump the contents of `page.html` (for Selenium) or `page.content`
(for Playwright) when the test fails
* Dumping Browser logs - for a browser-based test, it will dump anything that was `console.log`'ed. This should
work with Selenium and Playwright
* Arbitrary context you pass in, for example when testing an Active Record

  ```ruby
  person = Person.where(name: "Pat")
  with_clues(person.inspect) do
    expect(person.valid?).to eq(true)
  end
  ```

  If the test fails, `person.inspect` is included in the output

## Adding Your Own Clues

`with_clues` is intended as a diagnostic tool you can develop and enhance over time.  As your team writes more code or develops
more conventions, you can develop diagnostics as well.

To add one, create a class that implements `dump(notifier, context:)` or `dump(notifier, context:, page:)` or
`dump(notifier, context:, page:, captured_logs)`:

* `notifier` is a `WithClues::Notifier` that you should use to produce output via the following methods:
  * `notifier.notify` - output text, preceded with `[ with_clues ]` (this is so you can tell output from your code vs from `with_clues`)
  * `notifier.blank_line` - a blank line (no prefix)
  * `notifier.notify_raw` - output text without a prefix, useful for removing ambiguity about what is being output
* `context:` the context passed into `with_clues` (nil if it was omitted)
* `page:` will be given the Selenium or Playwright page object
* `captured_logs:` for Playwright, this will be the browser console logs captured inside the block

For example, suppose you want to output information about an Active Record like so:

```ruby
with_clues(person) do
  # some test
end
```

If this test fails, you output the person's ID and any `errors`.

Create this class, e.g. in `spec/support/active_record_clues.rb`:

```ruby
class ActiveRecordClues
  def dump(notifier, context:)
    if context.kind_of?(ActiveRecord::Base)
      notifier.notify "#{context.class}: id: #{context.id}"
      notifier.notify "#{context.class}: errors: #{context.errors.inspect}"
    end
  end
end
```

To use it, call `WithClues::Method.use_custom_clue`, for example, in your `spec_helper.rb`:

```ruby
require "with_clues"
require_relative "support/active_record_clues"

RSpec.configure do |c|
  c.include WithClues::Method
end

WithClues::Method.use_custom_clue ActiveRecordClues
```

You can use multiple clues by repeatedly calling `use_custom_clue`

## Developing

* Get set up with `bin/setup`
* Run tests with `bin/ci`
