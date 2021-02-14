module WithClues
  class Notifier
    def initialize(io)
      @io = io
    end

    def blank_line
      self.notify_raw("")
    end

    def notify(message)
      @io.puts "[ with_clues ] #{message}"
    end

    def notify_raw(message)
      @io.puts message
    end
  end
end
