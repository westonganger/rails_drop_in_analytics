module RailsLocalAnalytics
  class ApplicationController < ActionController::Base

    def root
      redirect_to tracked_requests_path(type: :page)
    end

  end
end
