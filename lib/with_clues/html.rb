module WithClues
  class Html
    def dump(notifier, page:, context:)
      notifier.blank_line
      notifier.notify "HTML {"
      notifier.blank_line
      if page.respond_to?(:html)
        notifier.notify_raw page.html
      elsif page.respond_to?(:native)
        notifier.notify_raw page.native
      else
        notifier.notify "[!] Something may be wrong. page (#{page.class}) does not respond to #html or #native"
      end
      notifier.blank_line
      notifier.notify "} END HTML"
    end
  end
end
