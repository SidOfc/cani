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
    command = :help unless respond_to? command
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
    config.remove!
  end

  def self.update
    api.update! && Completions.install! || exit(1) unless api.updated?
  end

  def self.edit
    system ENV.fetch('EDITOR', 'vim'), config.file
  end

  def self.use(feature = nil)
    viewer_browsers = (api.browsers.map(&:name) & config.browsers).map(&api.method(:find_browser))

    if feature && (feature = api.find_feature(feature))
      Api::Feature::Viewer.new(feature, viewer_browsers).render
      use
    elsif (chosen = Fzf.pick(Fzf.feature_rows,
                             header: 'use]   [' + Api::Feature.support_legend,
                             colors: %i[green light_black light_white light_black]))

      # chosen[2] is the index of the title column from Fzf.feature_rows
      if chosen.any? && (feature = api.find_feature(chosen[2]))
        Api::Feature::Viewer.new(feature, viewer_browsers).render
        use
      else
        exit
      end
    end
  end

  def self.show(brws = nil, version = nil)
    browser = api.find_browser brws

    if browser
      if version
        Fzf.pick Fzf.browser_feature_rows(browser, version),
                 header: "show:#{browser.title.downcase}:#{version}]   [#{Api::Feature.support_legend}",
                 colors: [:green, :light_black, :light_white]

        show browser.title
      else
        if (version = Fzf.pick(Fzf.browser_usage_rows(browser),
                               header: [:show, browser.title],
                               colors: %i[white light_black]).first)
          show browser.title, version
        else
          show
        end
      end
    else
      browser = api.find_browser Fzf.pick(Fzf.browser_rows,
                                          header: [:show],
                                          colors: %i[white light_black]).first

      show browser.title unless browser.nil?
    end
  end
end
