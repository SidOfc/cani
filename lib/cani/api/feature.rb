module Cani
  class Api
    class Feature
      attr_reader :title, :status, :spec, :stats, :percent, :name, :browser_note_nums, :notes, :notes_by_num, :description

      STATUSES = {
        'rec'   => 'rc',
        'unoff' => 'un',
        'other' => 'ot'
      }.freeze

      TYPES = {
        'y' => {symbol: '+', name: :default,     short: :sup},
        'a' => {symbol: '~', name: :partial,     short: :prt},
        'n' => {symbol: '-', name: :unsupported, short: :not},
        'p' => {symbol: '#', name: :polyfill,    short: :ply},
        'x' => {symbol: '@', name: :prefix,      short: :pfx},
        'd' => {symbol: '!', name: :flag,        short: :flg},
        'u' => {symbol: '?', name: :unknown,     short: :unk}
      }.freeze

      def initialize(attributes = {})
        @name         = attributes[:name].to_s.downcase
        @title        = attributes['title']
        @description  = attributes['description']
        @status       = STATUSES.fetch attributes['status'], attributes['status']
        @spec         = attributes['spec']
        @percent      = attributes['usage_perc_y']
        @notes        = attributes['notes'].split "\n"
        @notes_by_num = attributes['notes_by_num']
        @stats, @browser_note_nums = attributes['stats'].each_with_object([{}, {}]) do |(browser, info), (stts, notes)|
          stts[browser], notes[browser] = info.each_with_object([{}, {}]) do |(version, stat), (st, nt)|
            version.split('-').each do |v|
              nt[v] = stat.scan(/#(\d+)/).flatten
              st[v] = stat[' d '] ? 'd' : stat[0]
            end
          end
        end
      end

      def current_support
        @current_support ||= Cani.config.browsers.map do |browser|
          bridx = Cani.api.browsers.find_index { |brs| brs.name == browser }
          brwsr = Cani.api.browsers[bridx] unless bridx.nil?
          syms  = stats[browser].values.compact.last(Cani.config.versions)
                                .map { |s| TYPES[s][:symbol] || '' }
                                .join

          brwsr && syms + brwsr.abbr
        end.compact
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
