module WithClues
  class Html
    def dump(notifier, page)
      if !page.respond_to?(:html)
        notifier.notify "Something may be wrong. page (#{page.class}) does not respond to #html"
        return
      end
      notifier.blank_line
      notifier.notify "HTML {"
      notifier.blank_line
      notifier.notify_raw page.html
      notifier.blank_line
      notifier.notify "} END HTML"
    end
  end
end
