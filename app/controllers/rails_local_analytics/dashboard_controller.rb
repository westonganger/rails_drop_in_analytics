module RailsLocalAnalytics
  class DashboardController < ApplicationController
    PER_PAGE_LIMIT = 1000

    helper_method :pagination_page_number
    helper_method :display_columns

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

      if params[:start_date].present?
        @start_date = Date.parse(params[:start_date])
      else
        @start_date = Date.today
      end

      if params[:end_date].present?
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

      difference_where_conditions = params.require(:conditions).permit(*display_columns)

      current_total = fetch_records(
        start_date,
        end_date,
        difference_where_conditions: difference_where_conditions,
      ).first

      prev_total = fetch_records(
        prev_start_date,
        prev_end_date,
        difference_where_conditions: difference_where_conditions,
      ).first

      if prev_total
        diff = current_total - prev_total
      else
        diff = current_total
      end

      render json: {difference: diff}
    end

    private

    def fetch_records(start_date, end_date, difference_where_conditions: nil)
      aggregate_sql_field = "SUM(total)"

      tracked_requests = @klass
        .where("day >= ?", start_date)
        .where("day <= ?", end_date)
        .order("#{aggregate_sql_field} DESC")

      if difference_where_conditions
        tracked_requests = tracked_requests.where(difference_where_conditions)
      else
        tracked_requests = tracked_requests
          .limit(PER_PAGE_LIMIT)
          .offset(PER_PAGE_LIMIT * (pagination_page_number-1))

        if params[:filter].present?
          col, val = params[:filter].split("==")

          if display_columns.include?(col)
            tracked_requests = tracked_requests.where(col => val)
          else
            raise ArgumentError
          end
        end
      end

      if params[:search].present?
        tracked_requests = tracked_requests.multi_search(params[:search])
      end

      if params[:group_by].blank?
        pluck_columns = display_columns.dup
      else
        case params[:group_by]
        when "url_hostname_and_path"
          if display_columns.include?("url_hostname") && display_columns.include?("url_path")
            pluck_columns = [:url_hostname, :url_path]
          else
            raise ArgumentError
          end
        when "referrer_hostname_and_path"
          if display_columns.include?("referrer_hostname") && display_columns.include?("referrer_path")
            pluck_columns = [:referrer_hostname, :referrer_path]
          else
            raise ArgumentError
          end
        when *display_columns
          pluck_columns = [params[:group_by]]
        else
          raise ArgumentError
        end
      end

      group_by = pluck_columns.dup

      if difference_where_conditions
        pluck_columns = [aggregate_sql_field]
      else
        pluck_columns << aggregate_sql_field
      end

      tracked_requests
        .group(*group_by)
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

    def display_columns
      @display_columns ||= @klass.display_columns
    end

  end
end
