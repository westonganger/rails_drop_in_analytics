require "rails_local_analytics/version"
require "rails_local_analytics/engine"
require "browser/browser"

module RailsLocalAnalytics

  def self.record_request(request:, custom_attributes: nil)
    if request.is_a?(Hash)
      request_hash = request
    else
      ### Make request object generic so that it can be used outside of the controller

      request_hash = {
        referrer: request.referrer,
        host: request.host,
        path: request.path,
        user_agent: request.user_agent,
        http_accept_language: request.env["HTTP_ACCEPT_LANGUAGE"],
      }
    end

    json_hash = {
      day: Date.today.to_s,
      request_hash: request_hash,
      custom_attributes: custom_attributes,
    }

    if RailsLocalAnalytics.config.background_jobs
      json_str = JSON.generate(json_hash) # convert to json string so that its compatible with all job backends
      RecordRequestJob.perform_later(json_str)
    else
      RecordRequestJob.new.perform(json_hash)
    end
  end

  def self.config(&block)
    c = Config

    if block_given?
      block.call(c)
    else
      return c
    end
  end

  class Config
    @@background_jobs = true
    mattr_reader :background_jobs

    def self.background_jobs=(val)
      @@background_jobs = !!val
    end
  end

end
