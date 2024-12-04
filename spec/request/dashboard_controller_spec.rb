require 'spec_helper'

RSpec.describe RailsLocalAnalytics::DashboardController, type: :request do
  context "root" do
    it "redirects" do
      get rails_local_analytics.root_path
      expect(response).to redirect_to(rails_local_analytics.tracked_requests_path(type: :page))
    end
  end

  context "index" do
    before(:all) do
      2.times.each do
        TrackedRequestsByDaySite.create!(
          day: Date.today,
          url_hostname: "foo",
        )
        TrackedRequestsByDayPage.create!(
          day: Date.today,
          url_hostname: "foo",
          url_path: "bar",
        )
      end
    end

    it "renders" do
      get rails_local_analytics.tracked_requests_path(type: :foo)
      expect(response.status).to eq(404)
    end

    it "renders with type param" do
      get rails_local_analytics.tracked_requests_path(type: :site)
      expect(response.status).to eq(200)

      get rails_local_analytics.tracked_requests_path(type: :page)
      expect(response.status).to eq(200)
    end

    it "renders with start_date param" do
      get rails_local_analytics.tracked_requests_path(type: :site, start_date: 3.days.ago.to_date)
      expect(response.status).to eq(200)

      get rails_local_analytics.tracked_requests_path(type: :page, start_date: 3.days.ago.to_date)
      expect(response.status).to eq(200)
    end

    it "renders with end_date param" do
      get rails_local_analytics.tracked_requests_path(type: :site, end_date: 3.days.ago.to_date)
      expect(response.status).to eq(200)

      get rails_local_analytics.tracked_requests_path(type: :page, end_date: 3.days.ago.to_date)
      expect(response.status).to eq(200)
    end

    it "renders with search param" do
      get rails_local_analytics.tracked_requests_path(type: :site, search: "foo")
      expect(response.status).to eq(200)

      get rails_local_analytics.tracked_requests_path(type: :site, search: "foo bar")
      expect(response.status).to eq(200)

      get rails_local_analytics.tracked_requests_path(type: :page, search: "foo")
      expect(response.status).to eq(200)

      get rails_local_analytics.tracked_requests_path(type: :page, search: "foo bar")
      expect(response.status).to eq(200)
    end

    it "renders with group_by param" do
      get rails_local_analytics.tracked_requests_path(type: :site, group_by: "platform")
      expect(response.status).to eq(200)

      get rails_local_analytics.tracked_requests_path(type: :page, group_by: "referrer_path")
      expect(response.status).to eq(200)
    end
  end
end
