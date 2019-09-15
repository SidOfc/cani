require 'net/http'

require_relative 'api/browser'
require_relative 'api/feature'
require_relative 'api/feature/viewer'

module Cani
  class Api
    def initialize
      @data = load_data
    end

    def load_data(fetch: false)
      @upd = false
      data_file       = File.join Cani.config.directory, 'caniuse.json'
      data_exists     = File.exist? data_file
      data_up_to_date = data_exists ? (Time.now.to_i - File.mtime(data_file).to_i < Cani.config.expire.to_i)
                                    : false

      if !fetch && data_exists && data_up_to_date
        # data is available and up to date
        JSON.parse File.read(data_file)
      elsif (data = raw)
        @upd = true
        # data either doesn't exist or isn't up to date
        # if we can fetch new data, attempt to update
        FileUtils.mkdir_p File.dirname(data_file)
        File.open(data_file, 'w') { |f| f << data }
        JSON.parse data
      elsif data_exists
        # if we are unable fetch new data, fall back
        # to existing data if it exists
        JSON.parse File.read(data_file)
      else
        # no other option but fail since we have no data
        # and no way of fetching the data to display
        puts 'Cani fatal: no data available for display'
        exit 1
      end
    end

    def remove!
      data_file = File.join Cani.config.directory, 'caniuse.json'

      File.unlink data_file if File.exist? data_file
    end

    def update!
      @data = load_data fetch: true
    end

    def updated?
      @upd
    end

    def find_feature(name)
      name = Regexp.new name.to_s.downcase.gsub(/(\W)/, '.*'), :i
      idx  = features.find_index do |ft|
        ft.title.downcase.match(name) || ft.name.downcase.match(name)
      end

      features[idx] if idx
    end

    def find_features(name)
      name = Regexp.new name.to_s.downcase.gsub(/(\W)/, '.*'), :i
      features.select do |ft|
        ft.title.downcase.match(name) ||
          ft.name.downcase.match(name) ||
          ft.description.downcase.match(name)
      end
    end

    def find_browser(name)
      name = name.to_s.downcase
      idx  = browsers.find_index do |bwsr|
        [bwsr.title, bwsr.name, bwsr.abbr].map(&:downcase).include? name
      end

      browsers[idx] if idx
    end

    def browsers
      @browsers ||= @data['agents'].map do |(name, info)|
        Browser.new info.merge(name: name)
      end
    end

    def features
      @features ||= @data['data'].map { |(name, info)| Feature.new info.merge(name: name) }
    end

    def raw
      begin
        Net::HTTP.get URI(Cani.config.source)
      rescue
        nil
      end
    end
  end
end
