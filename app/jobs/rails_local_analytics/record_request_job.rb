module RailsLocalAnalytics
  class RecordRequestJob < ApplicationJob
    def perform(json)
      if json.is_a?(String)
        json = JSON.parse(json)
      end

      request_hash = json.fetch("request_hash")

      custom_attributes_by_type = json.fetch("custom_attributes")

      ["site", "page"].each do |type|
        case type
        when "site"
          klass = TrackedRequestsByDaySite
        when "page"
          klass = TrackedRequestsByDayPage
        end

        custom_attrs = custom_attributes_by_type && custom_attributes_by_type[type]

        attrs = build_attrs(klass, custom_attrs, request_hash)

        attrs["day"] = json.fetch("day")

        existing_record = klass.find_by(attrs)

        if existing_record
          existing_record.increment!(:total, 1)
        else
          klass.create!(attrs)
        end
      end
    end

    private

    def build_attrs(klass, attrs, request_hash)
      attrs ||= {}

      field = "url_hostname"
      if !skip_field?(field, attrs, klass)
        attrs[field] = request_hash.fetch("host")
      end

      field = "url_path"
      if !skip_field?(field, attrs, klass)
        attrs[field] = request_hash.fetch("path")
      end

      if request_hash.fetch("referrer").present?
        field = "referrer_hostname"
        if !skip_field?(field,attrs, klass)
          referrer_hostname, referrer_path = split_referrer(request_hash.fetch("referrer"))
          attrs[field] = referrer_hostname
        end

        field = "referrer_path"
        if !skip_field?(field, attrs, klass)
          if referrer_path.nil?
            referrer_hostname, referrer_path = split_referrer(request_hash.fetch("referrer"))
          end
          attrs[field] = referrer_path
        end
      end

      if request_hash.fetch("user_agent").present?
        field = "platform"
        if !skip_field?(field, attrs, klass)
          browser ||= create_browser_object(request_hash)
          attrs[field] = browser.platform.name
        end

        field = "browser_engine"
        if !skip_field?(field, attrs, klass)
          browser ||= create_browser_object(request_hash)
          attrs[field] = get_browser_engine(browser)
        end
      end

      return attrs
    end

    def split_referrer(referrer)
      uri = URI(referrer)

      if uri.host.present?
        return [
          uri.host,
          uri.path.presence,
        ]
      else
        strings = referrer.split("/", 2)
        return [
          strings[0],
          (strings[1].present? ? "/#{strings[1]}" : nil),
        ]
      end
    end

    def get_browser_engine(browser)
      if browser.webkit?
        # must come before all other checks because Firefox/Chrome on iOS devices is actually using Safari under the hood
        "webkit"
      elsif browser.chromium_based?
        "blink"
      elsif browser.firefox?
        "gecko"
      else
        nil # store nothing, data is not useful
      end
    end

    def create_browser_object(request_hash)
      Browser.new(
        request_hash.fetch("user_agent"),
        accept_language: request_hash.fetch("http_accept_language"),
      )
    end

    def skip_field?(field, attrs, klass)
      attrs&.has_key?(field) || !klass.column_names.include?(field)
    end

  end
end
