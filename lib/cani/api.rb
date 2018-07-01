require 'net/http'

module Cani
  class Api
    attr_reader :data

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

    def browsers
      @browsers ||= data['agents'].map do |(name, info)|
        Cani::Browser.new info.merge(name: name)
      end
    end

    def features
      @features ||= data['data'].values.map(&Cani::Feature.method(:new))
    end

    def raw
      Net::HTTP.get URI(Cani.config.source)
    end
  end
end
