require 'rubygems'
require 'feedzirra'

module Scrapers
  
  # Purpose: pull the given CraigsList autos listing RSS feed and parse new vehicles
  class CraigsList

    def cars
      @car_list
    end

    def initialize(city)
      @city = city
    end

    def scrape
      @car_list = []
      @feed = fetch_rss
      parse_feed
      @last_item_date = @feed.entries.first.published
    end

    private

    def build_url
      return "#{@city}.craigslist.org/cta/index.rss"
    end

    def fetch_rss
      # fetch pages in 100 listing blocks until we find the 
      feed = Feedzirra::Feed.fetch_and_parse(build_url)
    end

    def parse_feed
      invalid_entries = 0
      new_entries = 0
      @feed.entries.each do |item|
        if @last_item_date.nil? || item.published > @last_item_date
          details = parse item
          if !details.nil?
            details[:url] = item.url
            details[:raw] = {
              :title => item.title,
              :summary => item.summary
            }
            @car_list << details
            new_entries += 1
          else
            invalid_entries += 1
          end
        end
      end
      @car_list.each do |car|
        puts "Car: #{car.inspect}\n\r"
      end
      puts "#{invalid_entries} invalid, #{new_entries} new items found"
    end

    def parse item
      # common formats seem to be year make model
      # or make model year
      details = nil
      year_first_regex = /(\d{2,4})\s([\w\d]+)\s([\w\d]+[\-\s]?\d*)/
      year_last_regex = /([\w\d]+)\s([\w\d]+[\-\s]?\d*)\s(\d{2,4})/
      matches = item.title.match year_last_regex
      if !matches.nil? && !matches[1].nil? && !matches[2].nil? && !matches[3].nil?
        details = {
          :make => matches[1],
          :model => matches[2],
          :year => matches[3]
        }
      end
      matches = item.title.match year_first_regex
      if details.nil? && !matches.nil? && !matches[1].nil? && !matches[2].nil? && !matches[3].nil?
        details = {
          :make => matches[2],
          :model => matches[3],
          :year => matches[1]
        }
      end
      return if details.nil?
      price_regex = /\$([\d\,]+)/
      matches = item.title.match price_regex
      details[:price] = matches[1] unless matches.nil?
      mileage_regex = /([\d\,k\s]+)\s(thousand|thou)?\s?mile/
      matches = item.summary.match mileage_regex
      details[:mileage] = matches[1] unless matches.nil?
      details[:mileage] += 'k' if !details[:mileage].nil? && !matches[2].nil?
      details
    end

    #def numeric? item
    #  true if Float(item) rescue false
    #end

  end

end
