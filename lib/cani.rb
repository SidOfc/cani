# frozen_string_literal: true

require 'colorize'
require 'json'
require 'yaml'

require 'cani/version'
require 'cani/api'
require 'cani/fzf'
require 'cani/completions'

# Cani
module Cani
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
    puts Fzf.pick Fzf.feature_rows,
                  header: 'use]   [' + Api::Feature.support_legend,
                  colors: %i[green light_black light_white light_black]
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
