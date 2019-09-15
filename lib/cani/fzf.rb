module Cani
  module Fzf
    def self.pick(rows, **opts)
      if STDOUT.tty?
        unless executable?
          puts 'Cani fatal: command "fzf" not found, is it installed?'
          exit 1
        end

        rows   = tableize_rows(rows, **opts).join "\n"
        ohdr   = opts.fetch :header, []
        query  = "--query=\"#{opts[:query]}\"" if opts[:query]
        header = ohdr.is_a?(Array) ? [:cani, *ohdr].map { |v| v.to_s.downcase }.join(':')
                                   : 'cani:' + ohdr.to_s

        IO.popen("fzf --ansi --no-preview --header=\"[#{header}]\" #{query}", 'r+') do |io|
          io.write rows
          io.close_write
          io.read
        end.split '   '
      else
        # when output of any initial command is being piped
        # print results and exit this command.
        puts tableize_rows(rows).join "\n"
        exit
      end
    end

    def self.executable?
      @exe ||= system 'fzf --version > /dev/null 2>&1'
    end

    def self.dimensions
      @dimensions ||= [TTY::Screen.columns, TTY::Screen.rows]
    end

    def self.longest_title_size
      @longest_title_size ||= Cani.api.features.map(&:title).map(&:size).max
    end

    def self.feature_rows
      @feature_rows ||= Cani.api.features.map(&Fzf.method(:to_feature_row))
    end

    def self.to_feature_row(ft)
      pc = format('%.2f%%', ft.percent).rjust 6
      cl = { 'un' => :yellow, 'ot' => :magenta }.fetch ft.status, :green

      total_len = ft.current_support.map(&:size).reduce(&:+) + pc.size + 6 + (ft.current_support.size + 2) * 3
      rem_len   = [longest_title_size, 50, [dimensions.first - total_len, 24].max].min

      tt = format("%-#{rem_len}s", ft.title.size > rem_len ? ft.title[0...rem_len].strip + '..'
                                              : ft.title)

      [{ content: "[#{ft.status}]", color: cl }, pc,
       { content: tt, color: :default }, *ft.current_support]
    end

    def self.browser_rows
      @browser_rows ||= Cani.api.browsers.map do |bwsr|
        [{ content: bwsr.title, color: :default },
         'usage: ' + format('%.4f%%', bwsr.usage.values.reduce(0) { |total, add| total + add })]
      end
    end

    def self.browser_usage_rows(brwsr)
      brwsr.usage.map { |(v, u)| [{ content: v, color: :default }, 'usage: ' + format('%.4f%%', u)] }.reverse
    end

    def self.browser_feature_rows(brwsr, version)
      features_by_support = brwsr.features_for version

      Api::Feature::TYPES.flat_map do |(status, type)|
        if (features = features_by_support.fetch(type[:name], nil))
          features.map do |feature|
            color = { 'un' => :yellow, 'ot' => :magenta }.fetch feature[:status], :green
            [{ content: "[#{feature[:status]}]", color: color },
             "[#{type[:symbol]}]", { content: feature[:title], color: :default }]
          end
        end
      end.compact
    end

    def self.tableize_rows(rows, **opts)
      col_widths = []
      colors     = opts.fetch :colors, []

      rows.each do |row|
        row.each.with_index do |column, i|
          column = column[:content] if column.is_a? Hash
          col_width     = column.size
          col_widths[i] = col_width if col_width > col_widths[i].to_i
        end
      end

      rows.map do |row|
        row.map.with_index do |col, i|
          color  = col[:color] if col.is_a? Hash
          col    = col[:content] if col.is_a? Hash
          result = col.to_s.ljust col_widths[i]

          if STDOUT.tty?
            result.colorize(color || colors[i] || colors[-1] || :default)
                  .gsub '"', '\"'
          else
            result
          end
        end.join('   ').rstrip
      end
    end
  end
end
