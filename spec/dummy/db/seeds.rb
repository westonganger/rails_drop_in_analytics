site = Set.new
page = Set.new

hostname_options = ["example.com", "other-site.com", "some-product.example.com"]
platform_options = ["macOS", "Generic Linux", "Windows", "Android", "iOS (iPhone)", "iOS (iPad)"]
browser_engine_options = ["blink", "gecko", "webkit"]

[Date.today, (Date.today - 1.day)].each do |day|
  100_000.times.each do
    site << {
      day: day,
      url_hostname: hostname_options.sample,
      platform: platform_options.sample,
      browser_engine: browser_engine_options.sample,
    }

    page << {
      day: day,
      url_hostname: hostname_options.sample,
      url_path: "/posts/#{SecureRandom.hex(3)}/",
      referrer_hostname: hostname_options.sample,
      referrer_path: "/posts/#{SecureRandom.hex(3)}/",
    }
  end
end

site = site.to_a
page = page.to_a

[site, page].each do |list|
  list.each_with_index do |entry, index|
    list[index] = entry.merge(total: rand(1000))
  end
end


TrackedRequestsByDaySite.insert_all(site)
TrackedRequestsByDayPage.insert_all(page)
