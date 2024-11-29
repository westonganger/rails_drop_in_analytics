require 'spec_helper'

RSpec.describe RailsLocalAnalytics, type: :model do
  include ActiveJob::TestHelper

  it "exposes a version" do
    expect(described_class::VERSION).to match(/\d\.\d\.\d/)
  end

  context "config.background_jobs" do
    before do
      @prev_background_jobs = described_class.config.background_jobs
    end

    after do
      described_class.config.background_jobs = @prev_background_jobs
    end

    it "defaults to true" do
      expect(described_class.config.background_jobs).to eq(true)
    end

    it "stores a boolean value" do
      described_class.config.background_jobs = false
      expect(described_class.config.background_jobs).to eq(false)

      described_class.config.background_jobs = "foo"
      expect(described_class.config.background_jobs).to eq(true)

      described_class.config.background_jobs = true
      expect(described_class.config.background_jobs).to eq(true)
    end
  end

  context "record_request" do
    it "saves to database" do
      described_class.record_request(
        request: {
          host: "http://example.com",
          path: "/some/path",
          referrer: "http://example.com/some/other/path",
          user_agent: "some-user-agent",
          http_accept_language: "some-http-accept-language",
        },
      )

      perform_enqueued_jobs

      expect(TrackedRequestsByDaySite.last.attributes.except("id")).to eq({
        "browser_engine" => nil,
        "day" => Date.today,
        "platform" => "Unknown",
        "total" => 1,
        "url_hostname" => "http://example.com",
      })

      expect(TrackedRequestsByDayPage.last.attributes.except("id")).to eq({
        "day" => Date.today,
        "referrer_hostname" => "example.com",
        "referrer_path" => "/some/other/path",
        "total" => 1,
        "url_hostname" => "http://example.com",
        "url_path" => "/some/path",
      })
    end

    it "allow custom attributes" do
      described_class.record_request(
        request: {
          host: "http://example.com",
          path: "/some/path",
          referrer: "http://example.com/some/other/path",
          user_agent: "some-user-agent",
          http_accept_language: "some-http-accept-language",
        },
        custom_attributes: {
          TrackedRequestsByDaySite => {
            platform: "foo",
          },
          TrackedRequestsByDayPage => {
            referrer_hostname: "bar",
          },
        },
      )

      perform_enqueued_jobs


      expect(TrackedRequestsByDaySite.last.platform).to eq("foo")
      expect(TrackedRequestsByDayPage.last.referrer_hostname).to eq("bar")
    end
  end

end
