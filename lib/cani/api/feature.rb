module Cani
  class Api
    class Feature
      attr_reader :title, :status, :spec, :stats, :percent, :name

      STATUSES = {
        'rec'   => 'rc',
        'unoff' => 'un',
        'other' => 'ot'
      }.freeze

      TYPES = {
        'y' => {symbol: '+', name: :default,     short: :def},
        'a' => {symbol: '~', name: :partial,     short: :part},
        'n' => {symbol: '-', name: :unsupported, short: :unsup},
        'p' => {symbol: '#', name: :polyfill,    short: :poly},
        'x' => {symbol: '@', name: :prefix,      short: :prfx},
        'd' => {symbol: '!', name: :flag,        short: :flag},
        'u' => {symbol: '?', name: :unknown,     short: :unkn}
      }.freeze

      def initialize(attributes = {})
        @name    = attributes[:name].to_s.downcase
        @title   = attributes['title']
        @status  = STATUSES.fetch attributes['status'], attributes['status']
        @spec    = attributes['spec']
        @percent = attributes['usage_perc_y']
        @stats   = attributes['stats'].each_with_object({}) do |(k, v), h|
          h[k] = v.each_with_object({}) do |(vv, s), hh|
            vv.split('-').each { |ver| hh[ver] = s[0] }
          end
        end
      end

      def current_support
        @current_support ||= Cani.api.config.browsers.map do |browser|
          bridx = Cani.api.browsers.find_index { |brs| brs.name == browser }
          brwsr = Cani.api.browsers[bridx] unless bridx.nil?
          syms  = stats[browser].values.compact.last(Cani.api.config.versions)
                                .map { |s| TYPES[s][:symbol] || '' }
                                .join.rjust Cani.api.config.versions

          syms + brwsr.abbr
        end
      end

      def support_in(browser, version)
        TYPES.fetch(stats[browser.to_s][version.to_s.downcase], {})
             .fetch :name, :unknown
      end

      def self.support_legend
        TYPES.map { |_, v| "#{v[:short]}(#{v[:symbol]})" }.join ' '
      end
    end
  end
end
