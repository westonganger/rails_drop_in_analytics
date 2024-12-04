RailsLocalAnalytics::Engine.routes.draw do
  get "/tracked_requests/:type", to: "dashboard#index", as: :tracked_requests

  root to: "application#root"
end
