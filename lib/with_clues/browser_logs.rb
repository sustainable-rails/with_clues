module WithClues
  class BrowserLogs
    def dump(notifier, page:, context:, captured_logs: [])
      if !page.respond_to?(:driver)
        notifier.notify "Something may be wrong. page (#{page.class}) does not respond to #driver"
        return
      end
      if page.driver.respond_to?(:browser)
        logs = locate_logs(page.driver.browser, notifier: notifier)
        if !logs.nil?
          browser_logs = logs.get(:browser)
          notifier.notify "BROWSER LOGS {"
          browser_logs.each do |log|
            notifier.notify_raw log.message
          end
          notifier.notify "} END BROWSER LOGS"
        end
      else
        notifier.notify "[with_clues: #{self.class}] NO BROWSER LOGS: page.driver #{page.driver.class} does not respond to #browser"
      end
    end

  private

    def locate_logs(browser, notifier:)
      if browser.respond_to?(:logs)
        return browser.logs
      elsif browser.respond_to?(:manage)
        if browser.manage.respond_to?(:logs)
          return browser.manage.logs
        end
        notifier.notify "[with_clues: #{self.class}] NO BROWSER LOGS: page.driver.browser.manage #{browser.manage.class} does not respond to #logs"
      else
        notifier.notify "[with_clues: #{self.class}] NO BROWSER LOGS: page.driver.browser #{browser.class} does not respond to #manage or #logs"
      end
      nil
    end

  end
end
