module Cani
  class Browser
    attr_reader :name, :title, :prefix, :type, :versions, :usage, :abbr

    ABBR_MAP = { 'ios' => 'saf.ios' }.freeze

    def initialize(attributes = {})
      abbr = attributes['abbr'].downcase.gsub(/^\.+|\.+$/, '').tr('/', '.')

      @name     = attributes[:name].downcase
      @abbr     = ABBR_MAP.fetch abbr, abbr
      @title    = attributes['browser']
      @prefix   = attributes['prefix'].downcase
      @type     = attributes['type'].downcase
      @usage    = attributes['usage_global']
      @versions = @usage.keys
    end

    def features_for(version)
      @features ||= Cani.api.features.each_with_object({}) do |ft, h|
        type = ft.support_in(name, version)
        (h[type] ||= []) << { support: type, title: ft.title,
                              status: ft.status, percent: ft.percent }
      end
    end
  end
end
