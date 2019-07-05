# frozen_string_literal: true

require 'io/console'
require 'fileutils'
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

  def self.exec!(command, *args_and_options)
    return config if command.start_with? '-'

    args    = args_and_options.reject { |arg| arg.start_with? '-' }
    command = :help unless command && respond_to?(command)
    command = command.to_s.downcase.to_sym

    case command
    when :edit
      edit
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
    puts 'cani is dependent on fzf (https://github.com/junegunn/fzf)'.light_black
    puts 'for the interactive TUI to work. Without fzf,'.light_black
    puts 'commands can still be piped to get the regular (colorless) output.'.light_black
    puts ''
    puts 'Cani requires at least 20 lines and 40 cols to work properly,'.light_black
    puts 'this is not a hard limit but below this width long lines could wrap'.light_black
    puts 'a lot and significantly reduce visible information.'.light_black
    puts ''
    puts 'Usage:'.red
    puts '   cani'.yellow + ' [COMMAND [ARGUMENTS] [OPTIONS]]'
    puts ''
    puts 'Commands:'.red
    puts '   use '.blue + ' [FEATURE]             ' + 'show browser support for FEATURE'.light_black
    puts '   show'.blue + ' [BROWSER [VERSION]]   ' + 'show information about specific BROWSER and VERSION'.light_black
    puts '   '
    puts '   install_completions        '.blue      + 'installs completions for bash, zsh and fish'.light_black
    puts '   update                     '.blue      + 'force update api data and completions'.light_black
    puts '   edit                       '.blue      + 'edit configuration in $EDITOR'.light_black
    puts '   purge                      '.blue      + 'remove all completion, configuration and data'.light_black
    puts '                              '.blue      + 'stored by this cani'.light_black
    puts '   '
    puts '   help                       '.blue      + 'show this help'.light_black
    puts '   version                    '.blue      + 'print the version number'.light_black
    puts ''
    puts 'Options:'.red
    puts '   --[no-]modify              '.white + 'permanently enable/disable automatic adding/removing'.light_black
    puts '                              '.white + 'of source lines in shell configuration files'.light_black
    puts ''
    puts 'Examples:'.red
    puts '   cani'.yellow + ' use'.blue
    puts '   cani'.yellow + ' use'.blue  + ' \'box-shadow\''
    puts '   cani'.yellow + ' show'.blue + ' ie'
    puts '   cani'.yellow + ' show'.blue + ' ie 11'
    puts '   cani'.yellow + ' show'.blue + ' ie' + ' |'.light_black + ' cat'.yellow
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
    Completions.install! || exit(1)
  end

  def self.purge
    Completions.remove!
    api.remove!
    config.remove!
  end

  def self.update
    api.update! && install_completions unless api.updated?
  end

  def self.edit
    system ENV.fetch('EDITOR', 'vim'), config.file
  end

  def self.use(feature = nil)
    @use_min_depth ||= feature ? 1 : 0
    can_go_back      = !(config.nav_type?('forward') && @use_min_depth > 0)
    matches          = api.find_features feature

    return use if can_go_back && matches.empty?
    return Api::Feature::Viewer.new(matches.first).render if matches.count == 1

    chosen = Fzf.pick Fzf.feature_rows, query: feature,
                          header: 'use]   [' + Api::Feature.support_legend,
                          colors: %i[green light_black light_white light_black]

    # chosen[2] is the title column of a row returned by Fzf.feature_rows
    if chosen && chosen.any? && (feature = api.find_feature(chosen[2]))
      Api::Feature::Viewer.new(feature).render
      use
    else
      exit 0
    end
  end

  def self.show(brws = nil, version = nil)
    browser           = api.find_browser brws
    @show_min_depth ||= 0 + (browser ? 1 : 0) + (version ? 1 : 0)

    if browser
      if version
        chosen = Fzf.pick Fzf.browser_feature_rows(browser, version),
                          header: "show:#{browser.title.downcase}:#{version}]   [#{Api::Feature.support_legend}",
                          colors: [:green, :light_black, :light_white]

        if chosen.any? && (feature = api.find_feature(chosen[2]))
          Api::Feature::Viewer.new(feature).render
          show browser.title, version
        else
          show browser.title
        end
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
