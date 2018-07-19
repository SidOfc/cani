module Cani
  class Api
    class Feature
      class Viewer
        attr_reader :width, :height, :feature, :browsers, :viewable, :col_width, :table_width

        COLOR_PAIRS = {
          # foreground colors
          69  => [70,  -1], # green on default   (legend supported, feature status, percentage counter)
          213 => [214, -1], # orange on default  (legend partial, percentage counter)
          195 => [9,   -1], # red on default     (legend unsupported, percentage counter)
          133 => [128, -1], # magenta on default (legend flag, current feature status)
          12  => [75,  -1], # blue on default    (legend prefix)
          204 => [205, -1], # pink on default    (legend polyfill)
          99  => [8,   -1], # gray on default    (legend unknown)


          # background colors
          70  => [7,  70], # white on green      (supported feature)
          208 => [7, 214], # white on orange     (partial feature)
          196 => [7,   9], # white on red        (unsupported feature)
          134 => [7, 128], # white on magenta    (flag features)
          11  => [7,  75], # white on blue       (prefix feature)
          100 => [7,   8], # white on gray       (unknown features)
          205 => [7, 205], # white on pink       (polyfill features)

          # misc / one-off
          254 => [238, 255], # black on light gray (browser names, legend title)
        }.freeze

        COLORS = {
          # table headers
          header:      {fg: Curses.color_pair(254), bg: Curses.color_pair(254)},

          # support types
          default:     {fg: Curses.color_pair(69),  bg: Curses.color_pair(70)},
          partial:     {fg: Curses.color_pair(213), bg: Curses.color_pair(208)},
          prefix:      {fg: Curses.color_pair(12),  bg: Curses.color_pair(11)},
          polyfill:    {fg: Curses.color_pair(204), bg: Curses.color_pair(205)},
          flag:        {fg: Curses.color_pair(133), bg: Curses.color_pair(134)},
          unsupported: {fg: Curses.color_pair(195), bg: Curses.color_pair(196)},
          unknown:     {fg: Curses.color_pair(99),  bg: Curses.color_pair(100)},

          # statuses
          un:          {fg: Curses.color_pair(213), bg: Curses.color_pair(208)},
          ot:          {fg: Curses.color_pair(133), bg: Curses.color_pair(134)}
        }.freeze

        PERCENT_COLORS = {
          70..101 => {fg: Curses.color_pair(69),  bg: Curses.color_pair(70)},
          40..70  => {fg: Curses.color_pair(213), bg: Curses.color_pair(208)},
          0..40   => {fg: Curses.color_pair(195), bg: Curses.color_pair(196)}
        }.freeze

        ERAS    = 6  # range of eras to show around current era (incl current)
        COMPACT = 60 # column width at which to compress the layout
        PADDING = 1  # horizontal cell padding
        MARGIN  = 1  # horizontal cell margin

        def initialize(feature, browsers = Cani.api.browsers)
          @feature  = feature
          @browsers = browsers
          @viewable = browsers.size

          resize

          Curses.init_screen
          Curses.curs_set 0
          Curses.noecho
          Curses.cbreak

          if Curses.has_colors?
            Curses.use_default_colors
            Curses.start_color
          end

          COLOR_PAIRS.each do |(cn, clp)|
            Curses.init_pair cn, *clp
          end

          trap('INT', &method(:close))
          at_exit(&method(:close))
        end

        def close(*args)
          Curses.close_screen
        end

        def draw
          Curses.clear

          percent_num   = format '%.2f%%', feature.percent
          status_format = "[#{feature.status}]"
          percent_label = compact? ? '' : 'support: '
          legend_format = 'legend'.center table_width

          title_size    = [table_width - percent_num.size - percent_label.size - status_format.size - 3, 1].max
          title_size   += status_format.size if compact?
          title_chunks  = feature.title.chars.each_slice(title_size).map { |chrs| chrs.compact.join }

          type_count    = Feature::TYPES.keys.size
          offset_x      = ((width - table_width) / 2.0).floor
          offset_y      = ((height - ERAS - title_chunks.size - 10 - (type_count / [type_count, viewable].min.to_f).ceil) / 2.0).floor
          cy            = 0

          # positioning and drawing of percentage
          perc_num_xs = table_width - percent_num.size
          Curses.setpos offset_y + cy, offset_x + perc_num_xs
          Curses.attron percent_color(feature.percent) do
            Curses.addstr percent_num
          end

          # positioning and drawing of 'support: ' text
          # ditch this part all together when in compact mode
          unless compact?
            perc_lbl_xs = perc_num_xs - percent_label.size
            Curses.setpos offset_y + cy, offset_x + perc_lbl_xs
            Curses.addstr percent_label
          end

          # draw possibly multi-line feature title
          title_chunks.each do |part|
            Curses.setpos offset_y + cy, offset_x
            Curses.addstr part

            cy += 1
          end

          # status positioning and drawing
          # when compact? draw it on the second line instead of the first line at the end of the title
          cy       += 1
          status_yp = offset_y + (compact? ? 1 : 0)
          status_xp = offset_x + (compact? ? table_width - status_format.size
                                           : [title_size, feature.title.size].min + 1)

          Curses.setpos status_yp, status_xp
          Curses.attron status_color(feature.status) do
            Curses.addstr status_format
          end

          # meaty part, loop through browsers to create
          # the final feature table
          browsers[0...viewable].each.with_index do |browser, x|
            # some set up to find the current era for each browser
            # and creating a range around that to show past / coming support
            era_idx   = browser.most_popular_era_idx
            era_range = (era_idx - (ERAS / 2.0).floor + 1)..(era_idx + (ERAS / 2.0).ceil)
            bx        = offset_x + x * col_width + x
            by        = offset_y + cy

            # draw browser names
            Curses.setpos by, bx
            Curses.attron color(:header) do
              Curses.addstr browser.name.tr('_', '.').center(col_width)
            end

            # accordingly increment current browser y for the table header (browser names)
            # and an additional empty line below the table header
            by += 2

            # draw era's for the current browser
            era_range.each.with_index do |cur_era, y|
              era  = browser.eras[cur_era].to_s
              colr = color(feature.support_in(browser.name, era))

              # since the current era versions are displayed as 3-line rows
              # with an empty line before and after them, when we are at the current
              # era we increment era y by an additional 2 for the lines above,
              # whenever we are past the current era, increment by 2 for above plus 2
              # extra lines below the current era
              ey = by + y + (cur_era == era_idx ? 2 : (cur_era > era_idx ? 4 : 0))

              # only show relevant browsers
              if browser.usage[era].to_i >= 0.5 || (!era.empty? && cur_era >= era_idx)
                Curses.setpos ey, bx
                Curses.attron colr do
                  Curses.addstr era.center(col_width)
                end

                # previously, we only skipped some lines in order to create
                # enough space to create the 3-line current era
                # this snippet fills the line before and after the current era
                # with the same color that the era has for that browser / feature
                if cur_era == era_idx
                  [-1, 1].each do |relative_y|
                    Curses.setpos ey - relative_y, bx
                    Curses.attron colr do
                      Curses.addstr ' ' * col_width
                    end
                  end
                end
              end
            end
          end

          # increment current y by amount of eras
          # plus the 4 lines around the current era
          # plus the 1 line of browser names
          # plus the 2 blank lines above and below the eras
          cy += ERAS + 7

          # print legend header
          Curses.setpos offset_y + cy, offset_x
          Curses.attron color(:header) do
            Curses.addstr legend_format
          end

          # increment current y by 2
          # one for the header line
          # plus one for a blank line below it
          cy += 2

          # loop through all features to create a legend
          # showing which label belongs to which color
          Feature::TYPES.values.each_slice viewable do |group|
            group.compact.each.with_index do |type, lx|
              Curses.setpos offset_y + cy, offset_x + lx * col_width + lx
              Curses.attron color(type[:name], :fg) do
                Curses.addstr "#{type[:short]}(#{type[:symbol]})".center(col_width)
              end
            end

            # if there is more than one group, print the next
            # group on a new line
            cy += 1
          end

          Curses.refresh
        end

        def render
          loop do
            Curses.clear
            draw

            key = Curses.getch
            case key
            when Curses::KEY_RESIZE then resize
            else break unless key.nil?
            end
          end

          close
        end

        def colw
          colw = PADDING * 2 + browsers[0..viewable].map(&:max_column_width).max

          colw.even? ? colw : colw + 1
        end

        def tablew
          colw * viewable + viewable - 1
        end

        def resize
          @height, @width = IO.console.winsize
          @viewable       = browsers.size

          while tablew > @width
            @viewable -= 1
          end

          @col_width   = [colw, Feature::TYPES.map { |(_, h)| h[:short].size }.max + 3].max
          @table_width = tablew
        end

        def compact?
          width < COMPACT
        end

        def color(key, type = :bg)
          target = key.to_s.downcase.to_sym
          type   = type.to_sym

          COLORS.find { |(k, _)| k == target }.to_a
                .fetch(1, {})
                .fetch(type, COLORS[:default][type])
        end

        def status_color(status)
          color status, :fg
        end

        def percent_color(percent)
          PERCENT_COLORS.find { |(r, _)| r.include? percent }.to_a
                        .fetch(1, {})
                        .fetch(:fg, COLORS[:unknown][:fg])
        end
      end
    end
  end
end
