require_relative "html"
require_relative "browser_logs"
require_relative "notifier"
require_relative "private/custom_clue_method_analysis"

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
      if defined?(page)
        notifier.notify "Test failed: #{ex.message}"
        @@clue_classes[:require_page].each do |klass|
          klass.new.dump(notifier, context: context, page: page)
        end
      end
      raise ex
    end

    def self.use_custom_clue(klass)
      dump_method = klass.instance_method(:dump)
      analysis = WithClues::Private::CustomClueMethodAnalysis.from_method(dump_method)
      if analysis.standard_implementation?
        @@clue_classes[:custom] << klass
      elsif analysis.requires_page_object?
        @@clue_classes[:require_page] << klass
      else
        analysis.raise_exception!
      end
    end
  end
end
