#! /usr/bin/env ruby

$:.unshift File.dirname(__FILE__)
require 'lib/scrapers/craigs_list'

last_scraped = 1.minute.ago

cl = Scrapers::CraigsList.new 'austin'
cl.scrape

while true
  if (Time.now - last_scraped) > 15.minutes
    last_scraped = Time.now
    puts "Scraping at #{last_scraped}"
    cl.scrape
    sleep(60)
  end
end
