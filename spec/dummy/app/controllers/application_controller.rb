class ApplicationController < ActionController::Base
  after_action :record_page_view

  def example_action
    render html: "Hello World!"
  end

  private

  def record_page_view
    return if !request.format.html? && !request.format.json?

    RailsLocalAnalytics.record_request(
      request: request,
    )
  end
end
