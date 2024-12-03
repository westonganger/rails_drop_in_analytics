if Browser::VERSION.to_f < 6.0
  Browser::Base.class_eval do
    def chromium_based?
      false
    end
  end

  Browser::Chrome.class_eval do
    def chromium_based?
      true
    end
  end

  Browser::Edge.class_eval do
    def chromium_based?
      match? && ua.match?(/\bEdg\b/)
    end
  end
end
