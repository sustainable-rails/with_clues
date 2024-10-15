module WithClues
  class Html
    def dump(notifier, page:, context:, captured_logs: [])
      access_page_html = if page.respond_to?(:html)
                           ->(page) { page.html }
                         elsif page.respond_to?(:content)
                           ->(page) { page.content }
                         elsif page.respond_to?(:native)
                           ->(page) { page.native }
                         else
                           notifier.notify "Something may be wrong. page (#{page.class}) does not respond to #html, #native, or #content"
                           return
                         end
      notifier.blank_line
      notifier.notify "HTML {"
      notifier.blank_line
      notifier.notify_raw access_page_html.(page)
      notifier.blank_line
      notifier.notify "} END HTML"
      if captured_logs.any?
        notifier.notify "LOGS {"
        notifier.blank_line
        captured_logs.each do |log|
          notifier.notify_raw log
        end
        notifier.blank_line
        notifier.notify "} END LOGS"
      end
    end
  end
end
