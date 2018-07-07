require 'net/http'

require_relative 'api/browser'
require_relative 'api/feature'

module Cani
  class Api
    def initialize
      @data = begin
        load_file = File.join File.dirname(Cani.config.default), 'caniuse.json'
        if File.exist? load_file
          JSON.parse File.read(load_file)
        else
          data = raw
          FileUtils.mkdir_p File.dirname(load_file)
          File.open(load_file, 'w') { |f| f << data }
          JSON.parse data
        end
      end
    end

    def find_browser(name)
      name = name.to_s.downcase
      idx  = browsers.find_index do |bwsr|
        [bwsr.title, bwsr.name, bwsr.abbr].include? name
      end

      browsers[idx] if idx
    end

    def browsers
      @browsers ||= @data['agents'].map do |(name, info)|
        Browser.new info.merge(name: name)
      end
    end

    def features
      @features ||= @data['data'].values.map(&Feature.method(:new))
    end

    def raw
      Net::HTTP.get URI(Cani.config.source)
    end
  end
end
