module WithClues
  class BrowserLogs
    def dump(notifier, page:, context:)
      if !page.respond_to?(:driver)
        notifier.notify "Something may be wrong. page (#{page.class}) does not respond to #driver"
        return
      end
      if page.driver.respond_to?(:browser)
        if page.driver.browser.respond_to?(:manage)
          if page.driver.browser.manage.respond_to?(:logs)
            logs = page.driver.browser.manage.logs
            browser_logs = logs.get(:browser)
            notifier.notify "BROWSER LOGS {"
            browser_logs.each do |log|
              notifier.notify_raw log.message
            end
            notifier.notify "} END BROWSER LOGS"
          else
            notifier.notify "NO BROWSER LOGS: page.driver.browser.manage #{page.driver.browser.manage.class} does not respond to #logs"
          end
        else
          notifier.notify "NO BROWSER LOGS: page.driver.browser #{page.driver.browser.class} does not respond to #manage"
        end
      else
        notifier.notify "NO BROWSER LOGS: page.driver #{page.driver.class} does not respond to #browser"
      end
    end
  end
end
