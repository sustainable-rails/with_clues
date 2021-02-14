require_relative "html"
require_relative "browser_logs"
require_relative "notifier"

module WithClues
  module Method
    @@clue_classes = {
      require_page: [
        WithClues::BrowserLogs,
        WithClues::Html,
      ],
      custom: []
    }
    # Wrap any assertion with this method to get more
    # useful context and diagnostics when a test is
    # unexpectedly failing
    def with_clues(context=nil, &block)
      notifier = WithClues::Notifier.new($stdout)
      block.()
      notifier.notify "A passing test has been wrapped with `with_clues`. You should remove the call to `with_clues`"
    rescue Exception => ex
      notifier.notify context
      @@clue_classes[:custom].each do |klass|
        klass.new.dump(notifier, context: context)
      end
      if !defined?(page)
        raise ex
      end
      notifier.notify "Test failed: #{ex.message}"
      @@clue_classes[:require_page].each do |klass|
        klass.new.dump(notifier, context: context, page: page)
      end
      raise ex
    end

    def self.use_custom_clue(klass)
      @@clue_classes[:custom] << klass
    end
  end
end
