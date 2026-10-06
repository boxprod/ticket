require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1280, 800 ] do |options|
    options.binary = ENV.fetch("CHROMIUM", "/usr/bin/chromium")
    # Shares the current tab without the picker, as a person would choose it.
    options.add_argument("--auto-accept-this-tab-capture")
  end
end
