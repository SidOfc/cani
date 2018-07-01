module Cani
  class Browser
    attr_reader :name, :title, :prefix, :type, :versions, :usage

    def initialize(attributes = {})
      @name     = attributes[:name]
      @title    = attributes['browser']
      @prefix   = attributes['prefix']
      @type     = attributes['type']
      @usage    = attributes['usage_global']
      @versions = @usage.keys
    end

    def supported_in(version)
      features_for(version)[:supported]
    end

    def partial_in(version)
      features_for(version)[:partial]
    end

    def unsupported_in(version)
      features_for(version)[:unsupported]
    end

    def polyfill_in(version)
      features_for(version)[:polyfill]
    end

    def prefix_in(version)
      features_for(version)[:prefix]
    end

    def flag_in(version)
      features_for(version)[:flag]
    end

    def rows_for(**opts)
      return unless opts[:version] && opts[:columns] && opts[:types]

      opts[:types].flat_map do |type|
        next unless (fts = features_for(opts[:version])[type])
        fts.map { |ft| opts[:columns].map { |col| ft.fetch(col, '') } }
      end.compact
    end

    def features_for(version)
      @features ||= Cani.api.features.each_with_object({}) do |ft, h|
        type = ft.support_in(name, version)
        (h[type] ||= []) << ft.browser_info(name, version)
      end
    end
  end
end
