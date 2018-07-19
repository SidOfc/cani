module Cani
  class Api
    class Feature
      class Viewer
        attr_reader :width, :height, :feature, :browsers, :viewable, :col_width, :table_width

        COLOR_PAIRS = {
          # foreground colors
          69  => [70,  -1], # green on default   (legend supported, feature status, percentage counter)
          213 => [208, -1], # orange on default  (legend partial, percentage counter)
          195 => [160, -1], # red on default     (legend unsupported, percentage counter)
          133 => [134, -1], # magenta on default (legend flag, current feature status)
          12  => [75,  -1], # blue on default    (legend prefix)
          204 => [205, -1], # pink on default    (legend polyfill)
          99  => [239, -1], # gray on default    (legend unknown)

          # note background + foreground colors
          71  => [22,   70], # dark green on green     (supported feature)
          209 => [130, 208], # dark orange on orange   (partial feature)
          197 => [88,  160], # dark red on red         (unsupported feature)
          135 => [91,  134], # dark magenta on magenta (flag features)
          13  => [27,   75], # dark blue on blue       (prefix feature)
          101 => [235, 239], # dark gray on gray       (unknown features)
          206 => [127, 205], # dark pink on pink       (polyfill features)

          # background colors
          70  => [7,  70], # white on green      (supported feature)
          208 => [7, 208], # white on orange     (partial feature)
          196 => [7, 160], # white on red        (unsupported feature)
          134 => [7, 134], # white on magenta    (flag features)
          11  => [7,  75], # white on blue       (prefix feature)
          100 => [7, 239], # white on gray       (unknown features)
          205 => [7, 205], # white on pink       (polyfill features)

          # misc / one-off
          254 => [238, 255], # black on light gray (browser names, legend title)
          239 => [232, 236]
        }.freeze

        COLORS = {
          # table headers
          header:      {fg: Curses.color_pair(254), bg: Curses.color_pair(254)},

          # current era border
          era_border:  {fg: Curses.color_pair(239), bg: Curses.color_pair(239)},

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

        NOTE_COLORS = {
          default:     {fg: Curses.color_pair(71),  bg: Curses.color_pair(70)},
          partial:     {fg: Curses.color_pair(209), bg: Curses.color_pair(208)},
          prefix:      {fg: Curses.color_pair(13),  bg: Curses.color_pair(11)},
          polyfill:    {fg: Curses.color_pair(206), bg: Curses.color_pair(205)},
          flag:        {fg: Curses.color_pair(135), bg: Curses.color_pair(134)},
          unsupported: {fg: Curses.color_pair(197), bg: Curses.color_pair(196)},
          unknown:     {fg: Curses.color_pair(101), bg: Curses.color_pair(100)},
        }

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
          notes_format  = 'notes'.center table_width

          offset_x      = ((width - table_width) / 2.0).floor
          offset_y      = 1
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
          title_size    = [table_width - percent_num.size - percent_label.size - status_format.size - 3, 1].max
          title_size   += status_format.size if compact?
          title_chunks  = feature.title.chars.each_slice(title_size).map(&:join)

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
            by += 3

            # draw era's for the current browser
            era_range.each.with_index do |cur_era, y|
              era        = browser.eras[cur_era].to_s
              supp_type  = feature.support_in(browser.name, era)
              colr       = color supp_type
              is_current = cur_era == era_idx
              past_curr  = cur_era > era_idx
              top_pad    = 1
              bot_pad    = 1
              ey         = by + (y * 4)
              note_nums  = feature.browser_note_nums.fetch(browser.name, {})
                                                    .fetch(era, [])

              if is_current
                Curses.setpos ey - top_pad - 1, bx - 1
                Curses.attron(color(:era_border)) { Curses.addstr ' ' * (col_width + 2) }

                Curses.setpos ey + bot_pad + 1, bx - 1
                Curses.attron(color(:era_border)) { Curses.addstr ' ' * (col_width + 2) }
              end

              # only show visible / relevant browsers
              if browser.usage[era].to_i >= 0.5 || (!era.empty? && cur_era >= era_idx)
                ((ey - top_pad)..(ey + bot_pad)).each do |ry|
                  txt = bot_pad.zero? ? (ry >= ey + bot_pad ? era.to_s : ' ')
                                      : (ry == ey ? era.to_s : ' ')

                  Curses.setpos ry, bx
                  Curses.attron(colr) { Curses.addstr txt.center(col_width) }

                  if is_current
                    Curses.setpos ry, bx - 1
                    Curses.attron(color(:era_border)) { Curses.addstr ' ' }

                    Curses.setpos ry, offset_x + table_width + 2
                    Curses.attron(color(:era_border)) { Curses.addstr ' ' }
                  end
                end

                if note_nums.any?
                  Curses.setpos ey - top_pad, bx
                  Curses.attron(note_color(supp_type)) { Curses.addstr ' ' + note_nums.join(' ') }
                end
              end
            end
          end

          # increment current y by amount of eras
          # plus the 4 lines around the current era
          # plus the 1 line of browser names
          # plus the 2 blank lines above and below the eras
          cy += (ERAS - 1) * 4 + ERAS

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

          # add extra empty line after legend
          cy += 1

          notes_chunked = feature.notes.map { |nt| nt.chars.each_slice(table_width).map(&:join).map(&:strip) }
          num_chunked   = feature.notes_by_num.each_with_object({}) { |(k, nt), h| h[k] = nt.chars.each_slice(table_width - 5).map(&:join).map(&:strip) }

          if notes_chunked.any? || num_chunked.any?
            # print notes header
            Curses.setpos offset_y + cy, offset_x
            Curses.attron color(:header) do
              Curses.addstr notes_format
            end

            # add two new lines, one for the notes header
            # and one empty line below it
            cy += 2
          end

          notes_chunked.each do |chunks|
            chunks.each do |part|
              Curses.setpos offset_y + cy, offset_x
              Curses.addstr part
              cy += 1
            end

            cy += 1
          end

          num_chunked.each do |num, chunks|
            Curses.setpos offset_y + cy, offset_x
            Curses.attron color(:header) do
              Curses.addstr num.center(3)
            end
            chunks.each do |part|
              Curses.setpos offset_y + cy, offset_x + 5
              Curses.addstr part
              cy += 1
            end

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
          @table_width = tablew - 2 # vertical padding at start and end of current era line
        end

        def compact?
          width < COMPACT
        end

        def color(key, type = :bg, source = COLORS)
          target = key.to_s.downcase.to_sym
          type   = type.to_sym

          source.find { |(k, _)| k == target }.to_a
                .fetch(1, {})
                .fetch(type, source[:default][type])
        end

        def note_color(status)
          color status, :fg, NOTE_COLORS
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
