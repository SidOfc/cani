module Cani
  class Api
    class Browser
      attr_reader :name, :title, :prefix, :type, :versions, :usage, :abbr, :label, :eras

      ABBR_MAP  = { 'ios' => 'saf.ios' }.freeze
      LABEL_MAP = {
        'ie'      => 'Internet Explorer',
        'edge'    => 'Edge',
        'ff'      => 'Firefox',
        'chr'     => 'Chrome',
        'saf'     => 'Safari',
        'op'      => 'Opera',
        'saf.ios' => 'IOS Safari',
        'o.mini'  => 'Opera Mini',
        'and'     => 'Android Browser',
        'bb'      => 'BlackBerry Browser',
        'o.mob'   => 'Opera Mobile',
        'chr.and' => 'Chrome for Android',
        'ff.and'  => 'Firefox for Android',
        'ie.mob'  => 'Internet Explorer Mobile',
        'uc'      => 'UC Browser for android',
        'ss'      => 'Samsung Internet',
        'qq'      => 'QQ Browser',
        'baidu'   => 'Baidu Browser'
      }.freeze

      def initialize(attributes = {})
        abbr = attributes['abbr'].downcase.gsub(/^\.+|\.+$/, '').tr '/', '.'

        @abbr     = ABBR_MAP.fetch abbr, abbr
        @label    = LABEL_MAP.fetch abbr, abbr
        @name     = attributes[:name].downcase
        @title    = attributes['browser'].downcase
        @prefix   = attributes['prefix'].downcase
        @type     = attributes['type'].downcase
        @usage    = attributes['usage_global'].each_with_object({}) do |(v, u), h|
          v.split('-').each { |ver| h[ver] = u }
        end
        @eras = attributes['versions'].each_with_object([]) do |v, a|
          if v
            v.split('-').each { |ver| a << ver }
          else
            a << v
          end
        end
        @versions = @usage.keys
        @features = {}
      end

      def features_for(version)
        @features[version] ||= Cani.api.features.each_with_object({}) do |ft, h|
          type = ft.support_in name, version
          (h[type] ||= []) << { support: type, title: ft.title,
                                status: ft.status, percent: ft.percent }
        end
      end
    end
  end
end
