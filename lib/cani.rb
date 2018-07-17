# frozen_string_literal: true

require 'curses'
require 'colorize'
require 'json'
require 'yaml'

require 'cani/version'
require 'cani/api'
require 'cani/fzf'
require 'cani/completions'

# Cani
module Cani
  COLOR_MAP = {
    256 => [7, 0],                                                              # white text on black bg
    255 => [7, 7],                                                              # white
    254 => [0, 7],                                                              # black text on white bg
    253 => [0, 0],                                                              # black
    70  => [7,   70],  34  => [7,   34],  28  => [7,   28],  22  => [7,   22],  # green
    69  => [70,  0],   31  => [34,  0],   25  => [28,  0],   19  => [22,  0],   # green text only
    39  => [7,   39],  33  => [7,   33],  27  => [7,   27],  21  => [7,   21],  # blue
    38  => [39,  0],   32  => [33,  0],   26  => [27,  0],   20  => [21,  0],   # blue text only
    134 => [7,   134], 128 => [7,   128], 91  => [7,   91],  45  => [7,   54],  # magenta
    133 => [134, 0],   127 => [128, 0],   90  => [91,  0],   44  => [54,  0],   # magenta text only
    196 => [7,   196], 160 => [7,   160], 124 => [7,   124],                    # red
    195 => [196, 0],   159 => [160, 0],   123 => [124, 0],                      # red text only
    208 => [7,   208], 202 => [7,   202], 214 => [7,   214],                    # orange
    207 => [208, 0],   201 => [202, 0],   213 => [214, 0],                      # orange text only
    228 => [0,   228], 227 => [0,   227], 226 => [0,   226], 220 => [0,   220], # yellow
    225 => [228, 0],   224 => [227, 0],   223 => [226, 0],   222 => [220, 0]    # yellow text only
  }.freeze

  BG_SUPP_MAP = {
    default:     Curses.color_pair(70),
    partial:     Curses.color_pair(208),
    unsupported: Curses.color_pair(196),
    polyfill:    Curses.color_pair(134),
    prefix:      Curses.color_pair(134),
    flag:        Curses.color_pair(134),
    unknown:     Curses.color_pair(253)
  }

  PERCENT_MAP = {
    70..101 => Curses.color_pair(69),
    40..70  => Curses.color_pair(213),
    0..40   => Curses.color_pair(195)
  }.freeze

  def self.api
    @api ||= Api.new
  end

  def self.help
    puts "Cani #{VERSION} <https://github.com/SidOfc/cani>"
    puts ''
    puts 'Usage: cani [COMMAND [ARGUMENTS]]'
    puts ''
    puts 'Commands:'
    puts '   use FEATURE             show browser support for FEATURE'
    puts '   show BROWSER            show information about specific BROWSER'
    puts '   install_completions     installs completions for bash, zsh and fish'
    puts '   update                  force update api data and completions'
    puts '   purge                   remove all completion, configuration and data'
    puts '                           stored by this cani'
    puts '   '
    puts '   help                    show this help'
    puts '   version                 print the version number'
    puts ''
    puts 'Examples:'
    puts '   cani use'
    puts '   cani show ie'
    puts '   cani show chr.and'
    puts ''
    puts 'Statuses:'
    puts '   [ls]   WHATWG Living Standard'
    puts '   [rc]   W3C Recommendation'
    puts '   [pr]   W3C Proposed Recommendation'
    puts '   [cr]   W3C Candidate Recommendation'
    puts '   [wd]   W3C Working Draft'
    puts '   [ot]   Non-W3C, but reputable'
    puts '   [un]   Unofficial, Editor\'s draft or W3C "Note"'
  end

  def self.version
    puts VERSION
  end

  def self.install_completions
    Completions.install!
  end

  def self.purge
    Completions.remove!
    api.remove!
    api.config.remove!
  end

  def self.update
    api.update! && Completions.install! || exit(1) unless api.updated?
  end

  def self.edit
    system ENV.fetch('EDITOR', 'vim'), api.config.file
  end

  def self.use
    if (chosen = Fzf.pick(Fzf.feature_rows,
                          header: 'use]   [' + Api::Feature.support_legend,
                          colors: %i[green light_black light_white light_black]))

      view chosen[2] if chosen.any?
    end
  end

  def self.view(feature = Cani.api.config.args[1])
    Curses.init_screen
    Curses.curs_set 0
    Curses.noecho
    Curses.cbreak
    Curses.use_default_colors
    Curses.start_color if Curses.has_colors?

    COLOR_MAP.each_with_index do |arr, i|
      Curses.init_pair arr[0], *arr[1]
    end

    ft        = api.find_feature feature
    browsers  = (api.browsers.map(&:name) & api.config.browsers).map(&api.method(:find_browser))
    cwidth    = 14
    table_len = cwidth * browsers.size + browsers.size - 1
    psen      = 'global support: '
    perc      = format '%.2f%%', ft.percent
    scol      = ft.status == 'un' ? 201 : (ft.status == 'ot' ? 133 : 69)

    Curses.setpos 0, 0
    Curses.addstr ft.title

    Curses.setpos 0, ft.title.size + 1
    Curses.attron Curses.color_pair(69) do
      Curses.addstr "[#{ft.status}]"
    end

    Curses.setpos 0, table_len - perc.size - psen.size
    Curses.addstr psen

    Curses.setpos 0, table_len - perc.size
    Curses.attron PERCENT_MAP.find { |k, v| k.include? ft.percent }.last do
      Curses.addstr perc
    end

    browsers.each.with_index do |browser, x|
      current, usage = browser.usage.sort_by { |_, v| -v }.first
      era_idx        = browser.eras.find_index current
      era_range      = (era_idx - 2)..(era_idx + 3)
      x_offset       = x * cwidth + x
      y_init         = 4

      Curses.setpos y_init - 2, x_offset
      Curses.attron Curses.color_pair(254) do
        Curses.addstr browser.name.center(cwidth)
      end

      era_range.each.with_index do |current_era, y|
        era = browser.eras[current_era].to_s
        clr = BG_SUPP_MAP[ft.support_in(browser.name, era)] || Curses.color_pair(253)
        y_offset = y_init + (current_era < era_idx ? y : (current_era == era_idx ? y + 2 : y + 4))
        Curses.setpos y_offset, x_offset
        if browser.usage[era].to_i >= 0.5 || (!era.empty? && current_era >= era_idx)
          Curses.attron clr do
            Curses.addstr era.center(cwidth)
          end
        end

        if current_era == era_idx
          [-1, 1].each do |offset|
            Curses.setpos y_offset - offset, x_offset
            Curses.attron clr do
              Curses.addstr(' ' * cwidth)
            end
          end
        end
      end
    end

    Curses.refresh
    Curses.getch
  ensure
    Curses.close_screen
    use
  end

  def self.show(brws = api.config.args[1], version = api.config.args[2])
    browser = api.find_browser brws

    if browser
      if version
        Fzf.pick Fzf.browser_feature_rows(browser, version),
                 header: "show:#{browser.title.downcase}:#{version}]   [#{Api::Feature.support_legend}",
                 colors: [:green, :light_black, :light_white]

        show browser.title, nil
      else
        if (version = Fzf.pick(Fzf.browser_usage_rows(browser),
                               header: [:show, browser.title],
                               colors: %i[white light_black]).first)
          show browser.title, version
        else
          show nil, nil
        end
      end
    else
      browser = api.find_browser Fzf.pick(Fzf.browser_rows,
                                          header: [:show],
                                          colors: %i[white light_black]).first

      show browser.title, nil unless browser.nil?
    end
  end
end
