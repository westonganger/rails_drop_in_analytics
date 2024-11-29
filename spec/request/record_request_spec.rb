require 'spec_helper'

RSpec.describe "RailsLocalAnalytics#record_request", type: :request do
  include ActiveJob::TestHelper

  it "saves to database using normal request object" do
    get root_path
    expect(response.status).to eq(200)

    perform_enqueued_jobs

    expect(TrackedRequestsByDaySite.last.attributes.except("id")).to eq({
      "browser_engine" => nil,
      "day" => Date.today,
      "platform" => nil,
      "total" => 1,
      "url_hostname" => "www.example.com",
    })

    expect(TrackedRequestsByDayPage.last.attributes.except("id")).to eq({
      "day" => Date.today,
      "referrer_hostname" => nil,
      "referrer_path" => nil,
      "total" => 1,
      "url_hostname" => "www.example.com",
      "url_path" => "/",
    })
  end
end
