module Cani
  class Api
    class Feature
      attr_reader :title, :status, :spec, :stats, :percent

      STATUSES = {
        'rec'   => 'rc',
        'unoff' => 'un',
        'other' => 'ot'
      }.freeze

      TYPES = {
        'y' => {symbol: '+', name: :default,     short: :def,     color: :green},
        'a' => {symbol: '~', name: :partial,     short: :part,    color: :yellow},
        'n' => {symbol: '-', name: :unsupported, short: :unsupp,  color: :red},
        'p' => {symbol: '#', name: :polyfill,    short: :poly,    color: :magenta},
        'x' => {symbol: '@', name: :prefix,      short: :prefix,  color: :magenta},
        'd' => {symbol: '!', name: :flag,        short: :flag,    color: :magenta},
        'u' => {symbol: '?', name: :unknown,     short: :unknown, color: :default}
      }.freeze

      def initialize(attributes = {})
        @title   = attributes['title']
        @status  = STATUSES.fetch attributes['status'], attributes['status']
        @spec    = attributes['spec']
        @percent = attributes['usage_perc_y']
        @stats   = attributes['stats'].each_with_object({}) do |(k, v), h|
          h[k] = v.map { |(vv, s)| [vv.downcase, s.to_s[0] || ''] }.to_h
        end
      end

      def current_support
        @current_support ||= Cani.api.config.browsers.map do |browser|
          bridx = Cani.api.browsers.find_index { |brs| brs.name == browser }
          brwsr = Cani.api.browsers[bridx] unless bridx.nil?
          syms  = stats[browser].values.map { |s| TYPES[s][:symbol] || '' }
                                .join.rjust Cani.api.config.versions

          syms + brwsr.abbr
        end
      end

      def colors(browser, version)
        color = TYPES.fetch(stats[browser.to_s][version.to_s.downcase], {})
                     .fetch :color, :default
        fore  = color == :default ? :default : :black

        { color: fore, background: color }
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
