module RailsLocalAnalytics
  class Engine < ::Rails::Engine
    isolate_namespace RailsLocalAnalytics

    initializer "rails_local_analytics.load_static_assets" do |app|
      ### Expose static assets
      app.middleware.use ::ActionDispatch::Static, "#{root}/public"
    end

  end
end
