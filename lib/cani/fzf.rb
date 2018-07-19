module Cani
  module Fzf
    def self.pick(rows, **opts)
      unless executable?
        puts 'fatal: command "fzf" not found, is it installed?'
        exit 1
      end

      if STDOUT.tty?
        rows   = tableize_rows(rows, **opts).join "\n"
        ohdr   = opts.fetch :header, []
        header = ohdr.is_a?(Array) ? [:cani, *ohdr].map { |v| v.to_s.downcase }.join(':')
                                   : 'cani:' + ohdr.to_s

        `echo "#{rows}" | fzf --ansi --header="[#{header}]"`.split '   '
      else
        # when output of any initial command is being piped
        # print results and exit this command.
        puts tableize_rows(rows).join "\n"
        exit
      end
    end

    def self.executable?
      @exe ||= begin
        `command -v fzf`
        $?.success?
      end
    end

    def self.feature_rows
      @feature_rows ||= Cani.api.features.map do |ft|
        pc = format('%.2f%%', ft.percent).rjust 6
        cl = {'un' => :yellow, 'ot' => :magenta}.fetch ft.status, :green
        tt = format('%-24s', ft.title.size > 24 ? ft.title[0..23].strip + '..'
                                                : ft.title)

        [{content: "[#{ft.status}]", color: cl}, pc, tt, *ft.current_support]
      end
    end

    def self.browser_rows
      @browser_rows ||= Cani.api.browsers.map do |bwsr|
        [bwsr.title, 'usage: ' + format('%.4f%%', bwsr.usage.values.sum)]
      end
    end

    def self.browser_usage_rows(brwsr)
      brwsr.usage.map { |(v, u)| [v, 'usage: ' + format('%.4f%%', u)] }.reverse
    end

    def self.browser_feature_rows(brwsr, version)
      features_by_support = brwsr.features_for version

      Api::Feature::TYPES.flat_map do |(status, type)|
        if (features = features_by_support.fetch(type[:name], nil))
          features.map do |feature|
            color = {'un' => :yellow, 'ot' => :magenta}.fetch feature[:status], :green
            [{content: "[#{feature[:status]}]", color: color},
             "[#{type[:symbol]}]", feature[:title]]
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
