# frozen_string_literal: true

require 'io/console'
require 'curses'
require 'colorize'
require 'json'
require 'yaml'

require 'cani/api'
require 'cani/fzf'
require 'cani/config'
require 'cani/version'
require 'cani/completions'

# Cani
module Cani
  def self.api
    @api ||= Api.new
  end

  def self.config
    @settings ||= Config.new
  end


  def self.exec!(command, *args)
    command = :help unless command && respond_to?(command)
    command = command.to_s.downcase.to_sym

    case command
    when :use
      use args[0]
    when :show
      show args[0], args[1]
    when :update, :purge, :help, :version, :install_completions
      send command
    else
      help
    end
  end

  def self.help
    String.disable_colorization true unless STDOUT.tty?
    puts "Cani ".light_yellow + VERSION.to_s + ' <https://github.com/SidOfc/cani>'.light_black
    puts ''
    puts 'This command provides a TUI interface to access caniuse.com data.'.light_black
    puts 'It allows one to search by browser / version using the \'show\' command'.light_black
    puts 'and by feature using the \'use\' command. Pressing <enter> on a feature'.light_black
    puts 'in the \'use\' overview or calling \'use some-feature\' will display a'.light_black
    puts 'table as seen on caniuse.com using curses.'.light_black
    puts ''
    puts 'Usage:'.red
    puts '   cani'.yellow + ' [COMMAND [ARGUMENTS]]'
    puts ''
    puts 'Commands:'.red
    puts '   use '.blue + ' [FEATURE]             ' + 'show browser support for FEATURE'.light_black
    puts '   show'.blue + ' [BROWSER [VERSION]]   ' + 'show information about specific BROWSER and VERSION'.light_black
    puts '   '
    puts '   install_completions        '.blue      + 'installs completions for bash, zsh and fish'.light_black
    puts '   update                     '.blue      + 'force update api data and completions'.light_black
    puts '   purge                      '.blue      + 'remove all completion, configuration and data'.light_black
    puts '                              '.blue      + 'stored by this cani'.light_black
    puts '   '
    puts '   help                       '.blue      + 'show this help'.light_black
    puts '   version                    '.blue      + 'print the version number'.light_black
    puts ''
    puts 'Examples:'.red
    puts '   cani'.yellow + ' use'.blue
    puts '   cani'.yellow + ' use'.blue  + ' \'box-shadow\''
    puts '   cani'.yellow + ' show'.blue + ' ie'
    puts '   cani'.yellow + ' show'.blue + ' ie 11'
    puts ''
    puts 'Statuses:'.red
    puts '   [ls]'.green   + '   WHATWG Living Standard'.light_black
    puts '   [rc]'.green   + '   W3C Recommendation'.light_black
    puts '   [pr]'.green   + '   W3C Proposed Recommendation'.light_black
    puts '   [cr]'.green   + '   W3C Candidate Recommendation'.light_black
    puts '   [wd]'.green   + '   W3C Working Draft'.light_black
    puts '   [un]'.yellow  + '   Unofficial, Editor\'s draft or W3C "Note"'.light_black
    puts '   [ot]'.magenta + '   Non-W3C, but reputable'.light_black
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
    config.remove!
  end

  def self.update
    api.update! && Completions.install! || exit(1) unless api.updated?
  end

  def self.edit
    system ENV.fetch('EDITOR', 'vim'), config.file
  end

  def self.use(feature = nil)
    @use_min_depth ||= feature ? 1 : 0

    if feature && (feature = api.find_feature(feature))
      Api::Feature::Viewer.new(feature).render
      use unless config.nav_type?('forward') && @use_min_depth > 0
    elsif (chosen = Fzf.pick(Fzf.feature_rows,
                             header: 'use]   [' + Api::Feature.support_legend,
                             colors: %i[green light_black light_white light_black]))

      # chosen[2] is the index of the title column from Fzf.feature_rows
      if chosen.any? && (feature = api.find_feature(chosen[2]))
        Api::Feature::Viewer.new(feature).render
        use
      else
        exit
      end
    end
  end

  def self.show(brws = nil, version = nil)
    browser           = api.find_browser brws
    @show_min_depth ||= 0 + (browser ? 1 : 0) + (version ? 1 : 0)

    if browser
      if version
        Fzf.pick Fzf.browser_feature_rows(browser, version),
                 header: "show:#{browser.title.downcase}:#{version}]   [#{Api::Feature.support_legend}",
                 colors: [:green, :light_black, :light_white]

        show browser.title
      else
        exit if config.nav_type?('forward') && @show_min_depth > 1

        if (version = Fzf.pick(Fzf.browser_usage_rows(browser),
                               header: [:show, browser.title],
                               colors: %i[white light_black]).first)
          show browser.title, version
        else
          show
        end
      end
    else
      exit if config.nav_type?('forward') && @show_min_depth > 0

      browser = api.find_browser Fzf.pick(Fzf.browser_rows,
                                          header: [:show],
                                          colors: %i[white light_black]).first

      show browser.title unless browser.nil?
    end
  end
end
