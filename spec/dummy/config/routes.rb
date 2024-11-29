Rails.application.routes.draw do
  mount RailsLocalAnalytics::Engine, at: "/analytics"
  root to: "application#example_action"
end
