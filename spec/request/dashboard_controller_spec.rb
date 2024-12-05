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

    context "params[:group_by]" do
      it "raises error when field name is invalid" do
        expect {
          get rails_local_analytics.tracked_requests_path(type: :site, filter: "id==some-value")
        }.to raise_error(ArgumentError)
      end

      it "renders" do
        get rails_local_analytics.tracked_requests_path(type: :site, group_by: "platform")
        expect(response.status).to eq(200)

        get rails_local_analytics.tracked_requests_path(type: :page, group_by: "referrer_path")
        expect(response.status).to eq(200)
      end
    end

    context "params[:filter]" do
      it "raises error when field name is invalid" do
        expect {
          get rails_local_analytics.tracked_requests_path(type: :site, filter: "id==some-value")
        }.to raise_error(ArgumentError)
      end

      it "filters on specific field/value combos" do
        klass = TrackedRequestsByDaySite

        col = klass.display_columns.first

        klass.create!(
          day: Date.today,
          col => "some-value",
          platform: "foo",
        )

        klass.create!(
          day: Date.today,
          col => "foo",
        )

        klass.create!(
          day: Date.today,
          col => "some-value",
          platform: "bar",
        )

        get rails_local_analytics.tracked_requests_path(type: :site, filter: "#{col}==some-value")
        expect(response.status).to eq(200)
        expect(assigns(:results).map(&:first)).to eq(["some-value", "some-value"])
      end
    end
  end

  context "difference" do
    it "raises 404 for non-json requests" do
      expect {
        get rails_local_analytics.difference_tracked_requests_path(format: :html, type: :site, start_date: Date.today, end_date: Date.today, conditions: {url_hostname: "foo"})
      }.to raise_error(ActionController::RoutingError)
    end

    it "works when date range is a single day" do
      [Date.today, (Date.today - 1.day)].each do |day|
        TrackedRequestsByDaySite.create!(
          day: day,
          url_hostname: "foo",
          total: (day == Date.today ? 5 : 1)
        )

        TrackedRequestsByDaySite.create!(
          day: day,
          url_hostname: "bar",
        )
      end

      get rails_local_analytics.difference_tracked_requests_path(format: :json, type: :site, start_date: Date.today, end_date: Date.today, conditions: {url_hostname: "foo"})
      expect(response.status).to eq(200)
      expect(response.parsed_body).to eq({"difference" => 4})
    end

    it "works when date range spans multiple days" do
      [Date.today, (Date.today - 1.day), 2.days.ago.to_date, 3.days.ago.to_date].each do |day|
        TrackedRequestsByDaySite.create!(
          day: day,
          url_hostname: "foo",
          total: (day == Date.today ? 20 : 5)
        )

        TrackedRequestsByDaySite.create!(
          day: day,
          url_hostname: "bar",
          total: 1,
        )
      end

      get rails_local_analytics.difference_tracked_requests_path(format: :json, type: :site, start_date: (Date.today - 1.day), end_date: Date.today, conditions: {url_hostname: "foo"})
      expect(response.status).to eq(200)
      expect(response.parsed_body).to eq({"difference" => 15})
    end
  end
end
