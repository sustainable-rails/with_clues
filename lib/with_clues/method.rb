require_relative "html"
require_relative "browser_logs"
require_relative "notifier"

module WithClues
  module Method
    # Wrap any assertion with this method to get more
    # useful context and diagnostics when a test is
    # unexpectedly failing
    def with_clues(context=nil, &block)
      block.()
    rescue Exception => ex
      notifier = WithClues::Notifier.new($stdout)
      notifier.notify context
      if !defined?(page)
        raise ex
      end
      notifier.notify "Test failed: #{ex.message}"
      WithClues::BrowserLogs.new.dump(notifier,page)
      WithClues::Html.new.dump(notifier,page)
      raise ex
    end
  end
end
