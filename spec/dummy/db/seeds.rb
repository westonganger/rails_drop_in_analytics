date = Date.today

site = []
page = []

hostname_options = ["example.com", "other-site.com", "some-product.example.com"]
platform_options = ["macOS", "Generic Linux", "Windows", "Android", "iOS (iPhone)", "iOS (iPad)"]
browser_engine_options = ["blink", "gecko", "webkit"]

100_000.times.each do
  site << {
    day: date,
    url_hostname: hostname_options.sample,
    platform: platform_options.sample,
    browser_engine: browser_engine_options.sample,
    total: rand(1000),
  }

  page << {
    day: date,
    url_hostname: hostname_options.sample,
    url_path: "/posts/#{SecureRandom.hex(3)}/",
    referrer_hostname: hostname_options.sample,
    referrer_path: "/posts/#{SecureRandom.hex(3)}/",
    total: rand(1000),
  }
end

TrackedRequestsByDaySite.insert_all(site)
TrackedRequestsByDayPage.insert_all(page)
