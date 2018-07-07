module Cani
  module Fzf
    def self.pick(rows, **opts)
      if STDOUT.tty?
        rows   = tableize_rows(rows, **opts).join("\n")
        ohdr   = opts.fetch(:header, [])
        header = ohdr.is_a?(Array) ? [:cani, *ohdr].map { |v| v.to_s.downcase }.join(':')
                                   : 'cani:' + ohdr.to_s

        `echo "#{rows}" | fzf --ansi --header="[#{header}]"`.split('   ')
      else
        puts tableize_rows(rows).join("\n")
        exit
      end
    end

    def self.feature_rows
      Cani.api.map do |ft|
        st = Cani.api.config.statuses.fetch ft.status, ft.status
        pc = format('%.2f%%', ft.percent).rjust(6)
        tt = format('%-24s', ft.title.size > 24 ? ft.title[0..23].strip + '..'
                                                : ft.title)

        ["[#{st}]", pc, tt, *ft.current_support]
      end
    end

    def self.browser_rows
      Cani.api.browsers.map do |bwsr|
        [bwsr.title, 'usage: ' + format('%.4f%%', bwsr.usage.values.sum)]
      end
    end

    def self.browser_usage_rows(brwsr)
      brwsr.usage.map { |(v, u)| [v, 'usage: ' + format('%.4f%%', u)] }.reverse
    end

    def self.browser_feature_rows(brwsr, version)
      features_by_support = brwsr.features_for(version)
      Api::Feature::TYPES.flat_map do |(status, type)|
        if (features = features_by_support.fetch(type, nil))
          features.map do |feature|
            st = Cani.api.config.statuses.fetch feature[:status], feature[:status]

            ["[#{st}]", "[#{Api::Feature::SYMBOLS[status]}]", feature[:title]]
          end
        end
      end.compact
    end

    def self.tableize_rows(rows, **opts)
      col_widths = []
      colors     = opts.fetch(:colors, [])

      rows.each do |row|
        row.each.with_index do |column, i|
          col_width     = column.size
          col_widths[i] = col_width if col_width > col_widths[i].to_i
        end
      end

      rows.map do |row|
        row.map.with_index do |col, i|
          result = col.to_s.ljust(col_widths[i])

          if STDOUT.tty?
            result.colorize(colors[i] || colors[-1] || :default)
                  .gsub('"', '\"')
          else
            result
          end
        end.join('   ').rstrip
      end
    end
  end
end
