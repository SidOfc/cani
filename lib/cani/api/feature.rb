module Cani
  class Api
    class Feature
      attr_reader :title, :status, :spec, :stats, :percent

      TYPES = {
        'y' => :default,
        'a' => :partial,
        'n' => :unsupported,
        'p' => :polyfill,
        'x' => :prefix,
        'd' => :flag,
        'u' => :unknown
      }.freeze

      SHORT_TYPES = {
        'y' => :def,
        'a' => :part,
        'n' => :unsupp,
        'p' => :poly,
        'x' => :prefix,
        'd' => :flag,
        'u' => :unknown
      }.freeze

      SYMBOLS = {
        'y' => '+',
        'a' => '~',
        'x' => '@',
        'n' => '-',
        'p' => '#',
        'd' => '!',
        'u' => '?'
      }.freeze

      def initialize(attributes = {})
        @title   = attributes['title']
        @status  = attributes['status']
        @spec    = attributes['spec']
        @percent = attributes['usage_perc_y']
        @stats   = attributes['stats'].each_with_object({}) do |(k, v), h|
          h[k] = v.to_a.last(Cani.config.versions)
                  .map { |(vv, s)| [vv.downcase, s.to_s[0] || ''] }.to_h
        end
      end

      def current_support
        @current_support ||= Cani.config.show.map do |browser|
          bridx = Cani.api.browsers.find_index { |brs| brs.name == browser }
          brwsr = Cani.api.browsers[bridx] unless bridx.nil?
          syms  = stats[browser].values.map { |s| SYMBOLS[s] || '' }
                                .join.rjust(Cani.config.versions)

          syms + brwsr.abbr
        end
      end

      def support_in(browser, version)
        TYPES.fetch stats[browser.to_s][version.to_s], :unknown
      end

      def self.support_legend
        SHORT_TYPES.map { |t, v| "#{v}(#{SYMBOLS[t]})" }.join(' ')
      end
    end
  end
end
