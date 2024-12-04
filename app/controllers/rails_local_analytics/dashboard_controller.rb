module RailsLocalAnalytics
  class DashboardController < ApplicationController
    PER_PAGE_LIMIT = 1000

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

      if @results.size < PER_PAGE_LIMIT
        prev_start_date, prev_end_date = get_prev_dates(@start_date, @end_date)

        @prev_period_results = fetch_records(prev_start_date, prev_end_date)

        if @prev_period_results.size >= PER_PAGE_LIMIT
          @prev_period_results = nil
        end
      end
    end

    def difference
      case params.require(:type)
      when "site"
        @klass = TrackedRequestsByDaySite
      when "page"
        @klass = TrackedRequestsByDayPage
      end

      start_date = Date.parse(params.require(:start_date))
      end_date = Date.parse(params.require(:end_date))

      prev_start_date, prev_end_date = get_prev_dates(start_date, end_date)

      where_conditions = params.require(:conditions).permit(*@klass.display_columns)

      current_total = fetch_records(
        start_date,
        end_date,
        where_conditions: where_conditions,
        pluck_columns: ["SUM(total)"],
      ).first

      prev_total = fetch_records(
        prev_start_date,
        prev_end_date,
        where_conditions: where_conditions,
        pluck_columns: ["SUM(total)"],
      ).first

      if prev_total
        diff = current_total - prev_total
      else
        diff = current_total
      end

      render json: {difference: diff}
    end

    private

    def fetch_records(start_date, end_date, where_conditions: nil, pluck_columns: nil)
      tracked_requests = @klass
        .where("day >= ?", start_date)
        .where("day <= ?", end_date)
        .order(total: :desc)

      if where_conditions.nil? && pluck_columns.nil?
        tracked_requests = tracked_requests
          .limit(PER_PAGE_LIMIT)
          .offset(PER_PAGE_LIMIT * (pagination_page_number-1))
      end

      if where_conditions
        tracked_requests = tracked_requests.where(where_conditions)
      end

      if params[:search].present?
        tracked_requests = tracked_requests.multi_search(params[:search])
      end

      if params[:group_by].present?
        group_by_columns = [params[:group_by]]
        pluck_columns = [params[:group_by], "SUM(total)"]
      else
        group_by_columns = @klass.display_columns
        pluck_columns ||= @klass.display_columns + ["SUM(total)"]
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

    def get_prev_dates(start_date, end_date)
      if start_date == end_date
        prev_start_date = start_date - 1.day
        prev_end_date = prev_start_date
      else
        duration = end_date - start_date
        prev_start_date = start_date - duration
        prev_end_date = end_date - duration
      end
      return [prev_start_date, prev_end_date]
    end

  end
end
