class ApplicationController < ActionController::Base
  after_action :record_page_view

  def example_action
    html = <<~HTML
      Hello World!
      <br>
      <br>
      <a href="#{rails_local_analytics.root_path}">Go to Analytics Dashboard</a>
    HTML

    render(html: html.html_safe)
  end

  private

  def record_page_view
    return if !request.format.html? && !request.format.json?

    RailsLocalAnalytics.record_request(
      request: request,
    )
  end
end
