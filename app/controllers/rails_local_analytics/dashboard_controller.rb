module RailsLocalAnalytics
  class DashboardController < ApplicationController
    helper_method :pagination_page_number

    def index
      params[:type] ||= "page"

      case params[:type]
      when "site"
        @klass = TrackedRequestsByDaySite
      when "page"
        @klass = TrackedRequestsByDayPage
      else
        head 404
        return
      end

      if params[:group_by].present? && !@klass.display_columns.include?(params[:group_by])
        params[:group_by] = nil
      end

      if params[:start_date].present?
        @start_date = Date.parse(params[:start_date])
      else
        @start_date = Date.today
      end

      if params[:end_date]
        @end_date = Date.parse(params[:end_date])
      else
        @end_date = Date.today
      end

      if @end_date < @start_date
        @end_date = @start_date
      end

      @results = fetch_records(@start_date, @end_date)

      prev_start_date = @start_date - (@end_date - @start_date)
      prev_end_date = @end_date - (@end_date - @start_date)

      @prev_period_results = fetch_records(prev_start_date, prev_end_date)
    end

    private

    def fetch_records(start_date, end_date)
      per_page = 1000

      tracked_requests = @klass
        .where("day >= ?", @start_date)
        .where("day <= ?", @end_date)
        .order(total: :desc)
        .limit(per_page)
        .offset(per_page * (pagination_page_number-1))

      if params[:search].present?
        tracked_requests = tracked_requests.multi_search(params[:search])
      end

      if params[:group_by].present?
        group_by_columns = [params[:group_by]]
        pluck_columns = [params[:group_by], "SUM(total)"]
      else
        group_by_columns = @klass.display_columns
        pluck_columns = @klass.display_columns + ["SUM(total)"]
      end

      tracked_requests
        .group(*group_by_columns)
        .pluck(*pluck_columns)
    end

    def pagination_page_number
      page = params[:page].presence.to_i || 1
      page = 1 if page.zero?
      page
    end

  end
end
