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
    # colors on black background
    69  => [70,  0], # green on black      (feature status, percentage counter)
    213 => [214, 0], # orange on black     (percentage counter)
    253 => [0,   0], # black on black      (unknown feature)
    195 => [9,   0], # red on black        (percentage counter)
    133 => [128, 0], # magenta on black    (current feature status)
    201 => [214, 0], # orange on black     (current feature status)

    # white on colored background
    70  => [7, 70],  # white on green      (supported feature)
    208 => [7, 214], # white on orange     (partial feature)
    196 => [7, 9],   # white on red        (unsupported feature)
    134 => [7, 128], # white on magenta    (polyfill / prefix / flag features)

    # misc / one-off
    254 => [238, 255], # black on light gray (browser names)
  }.freeze

  BG_MAP = {
    browser:     Curses.color_pair(254),
    default:     Curses.color_pair(70),
    partial:     Curses.color_pair(208),
    unsupported: Curses.color_pair(196),
    polyfill:    Curses.color_pair(134),
    prefix:      Curses.color_pair(134),
    flag:        Curses.color_pair(134),
    unknown:     Curses.color_pair(253)
  }

  STATUS_MAP = {
    '*'  => Curses.color_pair(69),
    'un' => Curses.color_pair(201),
    'ot' => Curses.color_pair(133)
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

    ft       = api.find_feature feature
    browsers = (api.browsers.map(&:name) & api.config.browsers).map(&api.method(:find_browser))
    rng_size = 6
    cwidth   = 2 + browsers.reduce(0) do |num, browser|
      num2 = [browser.name.size, browser.versions.map(&:size).max].max
      num2 > num ? num2 : num
    end

    cwidth += 1 if cwidth % 2 != 0

    table_len = cwidth * browsers.size + browsers.size - 1
    psen      = 'global support: '
    perc      = format '%.2f%%', ft.percent
    ptot_len  = table_len - perc.size - psen.size
    yy        = 0
    titlesize = (ft.title.size >= (ptot_len - 2) ? (ptot_len - 2) : ft.title.size) - 7

    # draw 'global support: ' string at top right
    # before the percentage symbol
    Curses.setpos yy, ptot_len
    Curses.addstr psen

    # draw the global support percentage at outer most top right
    Curses.setpos yy, table_len - perc.size
    Curses.attron PERCENT_MAP.find { |k, v| k.include? ft.percent }.last do
      Curses.addstr perc
    end

    # draw feature status after the title
    Curses.setpos yy, titlesize + 1
    Curses.attron STATUS_MAP.fetch(ft.status, STATUS_MAP['*']) do
      Curses.addstr "[#{ft.status}]"
    end

    # draw title starting at yy, if the line is too long,
    # wrap on a new line
    ft.title.chars.each_slice(titlesize).each do |chars|
      Curses.setpos yy, 0
      Curses.addstr chars.compact.join
      yy += 1
    end

    # leave an empty line between feature meta and the table
    yy += 1

    browsers.each.with_index do |browser, x|
      era_idx   = browser.most_popular_era_idx
      era_range = (era_idx - (rng_size / 2.0).floor + 1)..(era_idx + (rng_size / 2.0).ceil)
      x_offset  = x * cwidth + x

      # cannot overwrite yy in this loop
      yyy = yy

      # draw browser name
      Curses.setpos yyy, x_offset
      Curses.attron BG_MAP[:browser] do
        Curses.addstr browser.name.center(cwidth)
      end

      # leave an empty line after browser name
      yyy += 2

      era_range.each.with_index do |current_era, y|
        era = browser.eras[current_era].to_s
        clr = BG_MAP[ft.support_in(browser.name, era)]

        # the following line ensures that the current era has two blank lines
        # above and below it, these are used to create a clear distinction
        # between the _before_, _current_ and _after_ eras
        y_offset = yyy + y + (current_era < era_idx ? 0 : (current_era == era_idx ? 2 : 4))

        # draw colored box containing the version number
        # background color is defined by BG_MAP which
        # maps feature support to a background color
        if browser.usage[era].to_i >= 0.5 || (!era.empty? && current_era >= era_idx)
          Curses.setpos y_offset, x_offset
          Curses.attron clr do
            Curses.addstr era.center(cwidth)
          end
        end

        # create same background line before and after current index
        # to make it "fat" e.g. indicating the current era for
        # that specific browser
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

    # 10 is the amount of era's we're showing (including current era)
    # plus the 4 lines surrounding the current era
    # plus the browser header line and the blank line after it
    yy += rng_size + 6

    # draw and wait for input to cancel
    Curses.refresh
    Curses.getch
  ensure
    Curses.close_screen
    # use
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
