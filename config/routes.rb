RailsLocalAnalytics::Engine.routes.draw do
  get "/tracked_requests/:type", to: "dashboard#index", as: :tracked_requests
  get "/tracked_requests/:type/difference", to: "dashboard#difference", as: :difference_tracked_requests, constraints: {format: :json}

  root to: "application#root"
end
